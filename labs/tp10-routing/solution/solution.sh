#!/bin/bash
# TP10 Solution complète

BASE_URL="http://localhost:9200"
CATEGORIES=("electronique" "electronique" "electronique" "vetements" "livres")

echo "=== Créer routing-demo-auto ==="
curl -s -X DELETE "$BASE_URL/routing-demo-auto" 2>/dev/null
curl -s -X PUT "$BASE_URL/routing-demo-auto" \
  -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":3,"number_of_replicas":1}}'

BULK_AUTO="/tmp/routing-auto.ndjson"
> "$BULK_AUTO"
for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((RANDOM % 5))]}"
  echo '{"index":{"_index":"routing-demo-auto"}}' >> "$BULK_AUTO"
  echo "{\"id\":$i,\"category\":\"$CAT\"}" >> "$BULK_AUTO"
done
curl -s -X POST "$BASE_URL/_bulk" -H 'Content-Type: application/x-ndjson' --data-binary @"$BULK_AUTO" \
  | jq -r '"Loaded: \(.items | length) errors: \(.errors)"'

curl -s -X POST "$BASE_URL/routing-demo-auto/_refresh"
echo ""
echo "=== Distribution automatique ==="
curl -s "$BASE_URL/_cat/shards/routing-demo-auto?v&h=shard,prirep,docs,node"

echo ""
echo "=== Créer routing-demo-forced ==="
curl -s -X DELETE "$BASE_URL/routing-demo-forced" 2>/dev/null
curl -s -X PUT "$BASE_URL/routing-demo-forced" \
  -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":3,"number_of_replicas":1}}'

for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((i % 5))]}"
  curl -s -X POST "$BASE_URL/routing-demo-forced/_doc?routing=$CAT" \
    -H 'Content-Type: application/json' \
    -d "{\"id\":$i,\"category\":\"$CAT\"}" > /dev/null
done
echo "300 docs avec routing forcé"

curl -s -X POST "$BASE_URL/routing-demo-forced/_refresh"
echo ""
echo "=== Distribution avec routing forcé (hotspot attendu) ==="
curl -s "$BASE_URL/_cat/shards/routing-demo-forced?v&h=shard,prirep,docs,node"

echo ""
echo "=== Requête SANS routing (3 shards interrogés) ==="
curl -s -X GET "$BASE_URL/routing-demo-forced/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"term":{"category":"electronique"}},"size":1}' \
  | jq -r '"Hits: \(.hits.total.value) | Shards: \(._shards.total)"'

echo ""
echo "=== Requête AVEC routing (1 shard interrogé) ==="
curl -s -X GET "$BASE_URL/routing-demo-forced/_search?routing=electronique" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"term":{"category":"electronique"}},"size":1}' \
  | jq -r '"Hits: \(.hits.total.value) | Shards: \(._shards.total)"'
