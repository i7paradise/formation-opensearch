#!/bin/bash
# TP8 — Resharding avec _reindex

BASE_URL="https://localhost:9200"
AUTH="-k -u admin:admin"

echo "=== Exercice 1 : Créer products-v2 avec 3 shards ==="
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
  }' | jq -r '"products-v2 créé: \(.acknowledged)"' 2>/dev/null

echo ""
echo "=== Exercice 2 : _reindex avec script Painless ==="
curl -s -X POST "$BASE_URL/_reindex" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{
    "source": { "index": "products" },
    "dest":   { "index": "products-v2" },
    "script": {
      "source": "ctx._source.migrated_at = params.ts",
      "params": { "ts": "2025-01-01T00:00:00Z" }
    }
  }' | jq -r '"Reindex: created=\(.created) updated=\(.updated) failed=\(.failures | length) took=\(.took)ms"' 2>/dev/null

echo ""
echo "=== Vérification shards products-v2 ==="
curl -s "$BASE_URL/_cat/shards/products-v2?v&h=index,shard,prirep,docs,store,node" $AUTH

echo ""
echo "=== Exercice 3 : Swap alias zero-downtime ==="
curl -s -X POST "$BASE_URL/_aliases" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{
    "actions": [
      { "add": { "index": "products", "alias": "products-current" } }
    ]
  }' | jq -r '"Alias initial: \(.acknowledged)"' 2>/dev/null

curl -s -X POST "$BASE_URL/_aliases" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{
    "actions": [
      { "remove": { "index": "products",    "alias": "products-current" } },
      { "add":    { "index": "products-v2", "alias": "products-current" } }
    ]
  }' | jq -r '"Swap alias: \(.acknowledged)"' 2>/dev/null

echo ""
echo "=== Vérification alias ==="
curl -s "$BASE_URL/_cat/aliases/products-current?v" $AUTH

echo ""
echo "=== Exercice 4 : Comparaison shards ==="
echo "--- products (source) ---"
curl -s "$BASE_URL/_cat/shards/products?v&h=index,shard,prirep,docs" $AUTH
echo "--- products-v2 (cible) ---"
curl -s "$BASE_URL/_cat/shards/products-v2?v&h=index,shard,prirep,docs" $AUTH
