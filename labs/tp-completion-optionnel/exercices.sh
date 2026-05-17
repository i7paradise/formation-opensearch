#!/bin/bash
# TP Optionnel — Completion Suggester

BASE_URL="http://localhost:9200"

echo "=== Créer index avec champ completion ==="
curl -s -X DELETE "$BASE_URL/products-suggest" 2>/dev/null
curl -s -X PUT "$BASE_URL/products-suggest" -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":1,"number_of_replicas":0},"mappings":{"properties":{"name":{"type":"text"},"category":{"type":"keyword"},"price":{"type":"float"},"suggest":{"type":"completion","analyzer":"simple"}}}}'

echo ""
echo "=== TODO : Indexer des produits avec champ suggest (input + weight) ==="

echo ""
echo "=== TODO : Requête completion avec prefix 'smart' ==="

echo ""
echo "=== TODO : Requête completion fuzzy avec 'smartphne' (faute de frappe) ==="
