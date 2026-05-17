#!/bin/bash
# TP8 — Routage : démonstration de l'algorithme

BASE_URL="https://localhost:9200"
AUTH="-k -u admin:admin"

echo "=== Exercice 1 : Créer index avec routing automatique ==="
curl -s -X DELETE "$BASE_URL/routing-demo-auto" $AUTH 2>/dev/null
curl -s -X PUT "$BASE_URL/routing-demo-auto" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{"settings": {"number_of_shards": 3, "number_of_replicas": 1}}'

echo ""
echo "=== Indexer 300 docs en bulk avec ID auto ==="
# Générer un fichier bulk
BULK_FILE="/tmp/routing-auto-bulk.ndjson"
> "$BULK_FILE"
CATEGORIES=("Électronique" "Vêtements" "Livres" "Sports" "Maison")
for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((RANDOM % 5))]}"
  echo '{"index":{"_index":"routing-demo-auto"}}' >> "$BULK_FILE"
  echo "{\"id\":$i,\"category\":\"$CAT\",\"value\":$RANDOM}" >> "$BULK_FILE"
done
curl -s -X POST "$BASE_URL/_bulk" $AUTH \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @"$BULK_FILE" | jq -r '"Errors: \(.errors) | Items: \(.items | length)"' 2>/dev/null

echo ""
echo "=== Observer la distribution ==="
curl -s "$BASE_URL/_cat/shards/routing-demo-auto?v&h=index,shard,prirep,docs,store,node" $AUTH

echo ""
echo "=== Exercice 2 : Routing forcé par catégorie ==="
# TODO : créez l'index routing-demo-forced et indexez avec ?routing=CATEGORIE
