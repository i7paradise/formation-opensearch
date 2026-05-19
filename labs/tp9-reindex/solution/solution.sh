#!/bin/bash
# TP8 — Solution complète : Resharding avec _reindex

BASE_URL="https://localhost:9200"
AUTH="-k -u admin:admin"

echo "=== [1/4] Nettoyage et création products-v2 ==="
curl -s -X DELETE "$BASE_URL/products-v2" $AUTH 2>/dev/null | jq -r '.acknowledged // empty' 2>/dev/null
curl -s -X PUT "$BASE_URL/products-v2" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": { "number_of_shards": 3, "number_of_replicas": 1 },
    "mappings": {
      "properties": {
        "name":        { "type": "text", "fields": { "raw": { "type": "keyword" } } },
        "category":    { "type": "keyword" },
        "price":       { "type": "float" },
        "description": { "type": "text" },
        "in_stock":    { "type": "boolean" },
        "created_at":  { "type": "date" }
      }
    }
  }' | jq -r '"[OK] products-v2 créé (3 shards): \(.acknowledged)"'

echo ""
echo "=== [2/4] _reindex avec script Painless ==="
curl -s -X POST "$BASE_URL/_reindex" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{
    "source": { "index": "products" },
    "dest":   { "index": "products-v2" },
    "script": {
      "source": "ctx._source.migrated_at = params.ts",
      "params": { "ts": "2025-01-01T00:00:00Z" }
    }
  }' | jq -r '"[OK] Reindex: created=\(.created) failed=\(.failures | length) took=\(.took)ms"'

echo ""
echo "=== Vérification : migrated_at présent ==="
curl -s -X GET "$BASE_URL/products-v2/_search" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{ "size": 1, "_source": ["name", "migrated_at"] }' \
  | jq '.hits.hits[0]._source'

echo ""
echo "=== [3/4] Swap alias zero-downtime ==="
# Créer alias initial sur products si besoin
curl -s -X POST "$BASE_URL/_aliases" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{"actions": [{ "add": { "index": "products", "alias": "products-current" } }]}' \
  | jq -r '"Alias initial: \(.acknowledged)"'

# Swap atomique
curl -s -X POST "$BASE_URL/_aliases" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{
    "actions": [
      { "remove": { "index": "products",    "alias": "products-current" } },
      { "add":    { "index": "products-v2", "alias": "products-current" } }
    ]
  }' | jq -r '"[OK] Swap atomique: \(.acknowledged)"'

echo ""
echo "=== [4/4] Validation finale ==="
echo "--- Alias ---"
curl -s "$BASE_URL/_cat/aliases/products-current?v" $AUTH
echo ""
echo "--- Shards products (1 shard) vs products-v2 (3 shards) ---"
curl -s "$BASE_URL/_cat/shards/products,products-v2?v&h=index,shard,prirep,docs" $AUTH

echo ""
echo "=== BONUS — Mode async ==="
echo "Démarrer un reindex asynchrone :"
echo "  POST /_reindex?wait_for_completion=false"
echo "  Puis : GET /_tasks/<task-id>"
echo "  Annuler : POST /_tasks/<task-id>/_cancel"
