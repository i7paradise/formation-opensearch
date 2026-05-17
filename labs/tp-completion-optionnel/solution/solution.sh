#!/bin/bash
# TP Optionnel Completion — Solution

BASE_URL="http://localhost:9200"

echo "=== Setup index ==="
curl -s -X DELETE "$BASE_URL/products-suggest" 2>/dev/null
curl -s -X PUT "$BASE_URL/products-suggest" -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":1,"number_of_replicas":0},"mappings":{"properties":{"name":{"type":"text"},"category":{"type":"keyword"},"price":{"type":"float"},"suggest":{"type":"completion","analyzer":"simple","max_input_length":50}}}}' | python3 -m json.tool

echo ""
echo "=== Indexer produits ==="
curl -s -X POST "$BASE_URL/_bulk" -H 'Content-Type: application/x-ndjson' \
  -d '{"index":{"_index":"products-suggest","_id":"1"}}
{"name":"Smartphone Pro Max 256Go","category":"Électronique","price":899.99,"suggest":{"input":["Smartphone Pro Max","Smartphone","téléphone"],"weight":10}}
{"index":{"_index":"products-suggest","_id":"2"}}
{"name":"Casque Audio Sans Fil Bluetooth","category":"Audio","price":199.99,"suggest":{"input":["Casque Audio","Casque Bluetooth","casque sans fil"],"weight":8}}
{"index":{"_index":"products-suggest","_id":"3"}}
{"name":"Ordinateur Portable Ultrabook 15","category":"Informatique","price":1299.0,"suggest":{"input":["Ordinateur Portable","Laptop","Ultrabook"],"weight":9}}
' | python3 -c "import json,sys; r=json.load(sys.stdin); print('Loaded:', len(r['items']))"

echo ""
echo "=== Completion basique : prefix 'smart' ==="
curl -s -X GET "$BASE_URL/products-suggest/_search" -H 'Content-Type: application/json' \
  -d '{"suggest":{"ps":{"prefix":"smart","completion":{"field":"suggest","size":5}}}}' | python3 -m json.tool

echo ""
echo "=== Completion fuzzy : prefix 'smartphne' (faute) ==="
curl -s -X GET "$BASE_URL/products-suggest/_search" -H 'Content-Type: application/json' \
  -d '{"suggest":{"ps":{"prefix":"smartphne","completion":{"field":"suggest","size":5,"fuzzy":{"fuzziness":1,"min_length":4,"prefix_length":2}}}}}' | python3 -m json.tool
