#!/bin/bash
# TP6 — Ingest Pipelines
# Complétez les sections marquées # TODO

BASE_URL="http://localhost:9200"

echo "=== Exercice 1 : Pipeline de normalisation ==="

# TODO: Créer le pipeline pipeline-normalisation
# Processors requis:
#   1. lowercase sur "category"
#   2. trim sur "description"
#   3. convert sur "price" → type "float"
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-normalisation" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Normalisation champs produit",
  "processors": [
    # TODO: lowercase
    # TODO: trim
    # TODO: convert price en float
  ]
}'

echo ""
echo "--- Test _simulate ---"
# TODO: Tester avec un document { "category": "ELECTRONIQUE", "description": "  Ordi  ", "price": "299.99" }
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-normalisation/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  "docs": [
    {
      "_source": {
        # TODO: ajouter les champs du document de test
      }
    }
  ]
}' | jq '.docs[0]._source'


echo ""
echo "=== Exercice 2 : Pipeline d enrichissement + on_failure ==="

# TODO: Créer pipeline-enrichissement
# Processors requis:
#   1. set → indexed_at: "{{{_ingest.timestamp}}}"  avec on_failure qui route vers "failed-products"
#   2. remove → champ "_tmp", ignore_missing: true
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-enrichissement" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Enrichissement et nettoyage",
  "processors": [
    # TODO: set indexed_at + on_failure
    # TODO: remove _tmp
  ]
}'

echo ""
echo "--- Indexation avec pipeline ---"
# TODO: Indexer ce document avec ?pipeline=pipeline-enrichissement
# { "name": "Vélo VTT Pro", "category": "sports", "price": 499.0, "_tmp": "draft" }
curl -s -X PUT "$BASE_URL/products/_doc/test-pipeline-001?pipeline=pipeline-enrichissement" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: corps du document
}'

echo ""
echo "--- Vérification : indexed_at doit être présent ---"
curl -s "$BASE_URL/products/_doc/test-pipeline-001" | jq '._source | {name, indexed_at}'


echo ""
echo "=== Exercice 3 : Processor conditionnel ==="

# TODO: Créer pipeline-segment
# Règle : price > 500 → segment "premium" ; sinon → segment "standard"
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-segment" \
  -H 'Content-Type: application/json' \
  -d '{
  "processors": [
    {
      "set": {
        # TODO: condition if + field "segment" + value "premium"
      }
    },
    {
      "set": {
        # TODO: condition if (prix <= 500) + field "segment" + value "standard"
      }
    }
  ]
}'

echo ""
echo "--- Test avec deux documents (price 799 et price 49) ---"
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-segment/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  "docs": [
    { "_source": { "name": "Laptop Pro", "price": 799 } },
    { "_source": { "name": "Souris USB",  "price": 49  } }
  ]
}' | jq '.docs[] | ._source | {name, price, segment}'


echo ""
echo "=== Exercice 4 : Chaîner plusieurs pipelines ==="

# TODO: Créer pipeline-produits-complet qui appelle en séquence :
#   1. pipeline-normalisation  (via processor "pipeline")
#   2. pipeline-enrichissement (via processor "pipeline")
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-produits-complet" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Pipeline maître : normalisation puis enrichissement",
  "processors": [
    # TODO: appel pipeline-normalisation
    # TODO: appel pipeline-enrichissement
  ]
}'

echo ""
echo "--- Test _simulate : toutes les transformations doivent s appliquer ---"
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-produits-complet/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  "docs": [
    {
      "_source": {
        "name": "Casque Audio BT",
        "category": "AUDIO",
        "description": "  Casque sans fil 30h autonomie.  ",
        "price": "89.99",
        "_tmp": "brouillon"
      }
    }
  ]
}' | jq '.docs[0]._source | {name, category, description, price, indexed_at}'

echo ""
echo "--- Indexation avec le pipeline maître ---"
curl -s -X PUT "$BASE_URL/products/_doc/test-master-001?pipeline=pipeline-produits-complet" \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "Clavier mécanique RGB",
  "category": "INFORMATIQUE",
  "description": "   Clavier TKL switches Cherry MX Red.   ",
  "price": "129.99",
  "_tmp": "draft"
}' | jq '{result, _id}'

echo ""
echo "=== TP6 terminé ! ==="
