#!/bin/bash
# TP Optionnel — Géolocalisation

BASE_URL="http://localhost:9200"

echo "=== Créer index stores ==="
curl -s -X DELETE "$BASE_URL/stores" 2>/dev/null
curl -s -X PUT "$BASE_URL/stores" -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":1,"number_of_replicas":0},"mappings":{"properties":{"name":{"type":"text","fields":{"keyword":{"type":"keyword"}}},"city":{"type":"keyword"},"location":{"type":"geo_point"},"stock":{"type":"integer"}}}}' | python3 -m json.tool

echo ""
echo "=== TODO : Indexer 5 magasins avec leurs coordonnées ==="
# TODO : POST /_bulk avec les 5 magasins (voir README)

echo ""
echo "=== TODO : geo_distance — magasins dans 300km de Paris ==="
# TODO : GET /stores/_search avec geo_distance query

echo ""
echo "=== TODO : geo_bounding_box — magasins en France ==="
# TODO : GET /stores/_search avec geo_bounding_box query
