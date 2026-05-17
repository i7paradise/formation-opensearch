#!/bin/bash
# TP Optionnel Geo — Solution

BASE_URL="http://localhost:9200"

echo "=== Setup ==="
curl -s -X DELETE "$BASE_URL/stores" 2>/dev/null
curl -s -X PUT "$BASE_URL/stores" -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":1,"number_of_replicas":0},"mappings":{"properties":{"name":{"type":"text"},"city":{"type":"keyword"},"location":{"type":"geo_point"},"stock":{"type":"integer"}}}}' | python3 -m json.tool

curl -s -X POST "$BASE_URL/_bulk" -H 'Content-Type: application/x-ndjson' \
  -d '{"index":{"_index":"stores","_id":"1"}}
{"name":"Store Paris Centre","city":"Paris","location":{"lat":48.8566,"lon":2.3522},"stock":150}
{"index":{"_index":"stores","_id":"2"}}
{"name":"Store Lyon Bellecour","city":"Lyon","location":{"lat":45.7578,"lon":4.8320},"stock":89}
{"index":{"_index":"stores","_id":"3"}}
{"name":"Store Marseille Vieux-Port","city":"Marseille","location":{"lat":43.2965,"lon":5.3698},"stock":210}
{"index":{"_index":"stores","_id":"4"}}
{"name":"Store Bordeaux Quinconces","city":"Bordeaux","location":{"lat":44.8378,"lon":-0.5792},"stock":67}
{"index":{"_index":"stores","_id":"5"}}
{"name":"Store Lille Grand-Place","city":"Lille","location":{"lat":50.6292,"lon":3.0573},"stock":45}
' | python3 -c "import json,sys; r=json.load(sys.stdin); print('Loaded:', len(r['items']), 'errors:', r['errors'])"

echo ""
echo "=== Magasins dans 300km de Paris ==="
curl -s -X GET "$BASE_URL/stores/_search" -H 'Content-Type: application/json' \
  -d '{"query":{"geo_distance":{"distance":"300km","location":{"lat":48.8566,"lon":2.3522}}},"sort":[{"_geo_distance":{"location":{"lat":48.8566,"lon":2.3522},"order":"asc","unit":"km"}}]}' | python3 -m json.tool

echo ""
echo "=== Bounding box France ==="
curl -s -X GET "$BASE_URL/stores/_search" -H 'Content-Type: application/json' \
  -d '{"query":{"geo_bounding_box":{"location":{"top_left":{"lat":51.0,"lon":-2.0},"bottom_right":{"lat":43.0,"lon":6.0}}}}}' | python3 -m json.tool

echo ""
echo "=== Agrégation geo_distance ==="
curl -s -X GET "$BASE_URL/stores/_search" -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"zones":{"geo_distance":{"field":"location","origin":{"lat":48.8566,"lon":2.3522},"unit":"km","ranges":[{"key":"<100km","to":100},{"key":"100-400km","from":100,"to":400},{"key":">400km","from":400}]},"aggs":{"stock":{"sum":{"field":"stock"}}}}}}' | python3 -m json.tool
