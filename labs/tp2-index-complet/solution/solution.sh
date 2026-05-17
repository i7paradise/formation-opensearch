#!/bin/bash
# TP2 — Solution complète

BASE_URL="http://localhost:9200"

echo "=== Créer l'index ==="
curl -s -X DELETE "$BASE_URL/produits_complet" 2>/dev/null
curl -s -X PUT "$BASE_URL/produits_complet" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0, "dynamic": "strict" },
    "mappings": {
      "properties": {
        "name": { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
        "description": { "type": "text" },
        "category": { "type": "keyword" },
        "price": { "type": "float" },
        "stock_quantity": { "type": "integer" },
        "in_stock": { "type": "boolean" },
        "created_at": { "type": "date" },
        "location": { "type": "geo_point" },
        "attributes": {
          "type": "nested",
          "properties": { "key": { "type": "keyword" }, "value": { "type": "keyword" } }
        },
        "tags": { "type": "keyword" }
      }
    }
  }'

echo ""
echo "=== Indexer document 1 ==="
curl -s -X PUT "$BASE_URL/produits_complet/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Smartphone Pro Max 256Go",
    "description": "Smartphone haut de gamme avec écran AMOLED",
    "category": "Électronique",
    "price": 899.99,
    "stock_quantity": 42,
    "in_stock": true,
    "created_at": "2024-01-15T10:30:00Z",
    "location": { "lat": 48.8566, "lon": 2.3522 },
    "attributes": [{ "key": "couleur", "value": "Noir" }, { "key": "stockage", "value": "256Go" }],
    "tags": ["smartphone", "5G", "AMOLED"]
  }'

echo ""
echo "=== Analyser text vs keyword ==="
echo "--- Champ text (name) ---"
curl -s -X POST "$BASE_URL/produits_complet/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{ "field": "name", "text": "Smartphone Pro Max 256Go" }'

echo "--- Champ keyword (name.keyword) ---"
curl -s -X POST "$BASE_URL/produits_complet/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{ "field": "name.keyword", "text": "Smartphone Pro Max 256Go" }'

echo ""
echo "=== Tester dynamic strict ==="
curl -s -X PUT "$BASE_URL/produits_complet/_doc/99" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Produit test",
    "category": "Test",
    "price": 10.0,
    "stock_quantity": 1,
    "in_stock": true,
    "created_at": "2024-01-01T00:00:00Z",
    "champ_inconnu": "doit échouer"
  }'
