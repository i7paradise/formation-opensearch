#!/bin/bash
# TP2 — Créer un index complet avec tous les types de champs
# Exécuter depuis le dossier labs/tp2-index-complet/

BASE_URL="http://localhost:9200"

echo "=== Exercice 1 : Créer l'index produits_complet ==="
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
  }' | python3 -m json.tool

echo ""
echo "=== Vérifier le mapping ==="
curl -s "$BASE_URL/produits_complet/_mapping" | python3 -m json.tool

echo ""
echo "=== Exercice 2 : Indexer des documents ==="
# TODO : Indexez le document 1 (smartphone) avec PUT /produits_complet/_doc/1
# TODO : Indexez le document 2 (casque audio) avec PUT /produits_complet/_doc/2

echo ""
echo "=== Exercice 3 : Analyser text vs keyword ==="
# TODO : Utilisez _analyze sur le champ 'name' avec le texte "Smartphone Pro Max 256Go"
# TODO : Utilisez _analyze sur le champ 'name.keyword' avec le même texte

echo ""
echo "=== Exercice 4 : Tester dynamic strict ==="
# TODO : Tentez d'indexer un document avec un champ 'champ_inconnu'
# Observez l'erreur strict_dynamic_mapping_exception
