#!/bin/bash
# TP8 Solution complète

BASE_URL="https://localhost:9200"
AUTH="-k -u admin:admin"
CATEGORIES=("Électronique" "Électronique" "Électronique" "Vêtements" "Livres")

echo "=== Créer routing-demo-auto ==="
curl -s -X DELETE "$BASE_URL/routing-demo-auto" $AUTH 2>/dev/null
curl -s -X PUT "$BASE_URL/routing-demo-auto" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":3,"number_of_replicas":1}}' | python3 -m json.tool

BULK_AUTO="/tmp/routing-auto.ndjson"
> "$BULK_AUTO"
for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((RANDOM % 5))]}"
  echo '{"index":{"_index":"routing-demo-auto"}}' >> "$BULK_AUTO"
  echo "{\"id\":$i,\"category\":\"$CAT\"}" >> "$BULK_AUTO"
done
curl -s -X POST "$BASE_URL/_bulk" $AUTH -H 'Content-Type: application/x-ndjson' --data-binary @"$BULK_AUTO" | python3 -c "import json,sys; r=json.load(sys.stdin); print('Loaded:', len(r['items']), 'errors:', r['errors'])"

echo ""
echo "=== Distribution automatique ==="
curl -s "$BASE_URL/_cat/shards/routing-demo-auto?v&h=shard,prirep,docs,node" $AUTH

echo ""
echo "=== Créer routing-demo-forced ==="
curl -s -X DELETE "$BASE_URL/routing-demo-forced" $AUTH 2>/dev/null
curl -s -X PUT "$BASE_URL/routing-demo-forced" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":3,"number_of_replicas":1}}' | python3 -m json.tool

for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((i % 5))]}"
  ENCODED_CAT=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CAT'))")
  curl -s -X POST "$BASE_URL/routing-demo-forced/_doc?routing=$ENCODED_CAT" $AUTH \
    -H 'Content-Type: application/json' \
    -d "{\"id\":$i,\"category\":\"$CAT\"}" > /dev/null
done
echo "300 docs avec routing forcé"

echo ""
echo "=== Distribution avec routing forcé (hotspot attendu) ==="
curl -s "$BASE_URL/_cat/shards/routing-demo-forced?v&h=shard,prirep,docs,node" $AUTH

echo ""
echo "=== Requête SANS routing (3 shards interrogés) ==="
curl -s -X GET "$BASE_URL/routing-demo-forced/_search" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{"query":{"term":{"category":"Électronique"}},"size":1}' \
  | python3 -c "import json,sys; r=json.load(sys.stdin); print('Hits:', r['hits']['total']['value'], '| Shards:', r['_shards']['total'])"

echo ""
echo "=== Requête AVEC routing (1 shard interrogé) ==="
curl -s -X GET "$BASE_URL/routing-demo-forced/_search?routing=%C3%89lectronique" $AUTH \
  -H 'Content-Type: application/json' \
  -d '{"query":{"term":{"category":"Électronique"}},"size":1}' \
  | python3 -c "import json,sys; r=json.load(sys.stdin); print('Hits:', r['hits']['total']['value'], '| Shards:', r['_shards']['total'])"
