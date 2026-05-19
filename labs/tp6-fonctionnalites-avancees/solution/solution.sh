#!/bin/bash
# TP6 — Solution complète — Ingest Pipelines

BASE_URL="http://localhost:9200"

echo "================================================"
echo " TP6 — Solution : Ingest Pipelines"
echo "================================================"


# ============================================
# EXERCICE 1 : Pipeline de normalisation
# ============================================
echo ""
echo "=== Exercice 1 : Pipeline de normalisation ==="

curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-normalisation" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Normalisation champs produit",
  "processors": [
    { "lowercase": { "field": "category",    "ignore_missing": true } },
    { "trim":      { "field": "description", "ignore_missing": true } },
    { "convert":   { "field": "price",       "type": "float", "ignore_missing": true } }
  ]
}' | jq '{acknowledged}'

echo ""
echo "--- Test _simulate ---"
# _simulate transforme le document sans l indexer — toujours faire ça avant la prod
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-normalisation/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  "docs": [
    {
      "_source": {
        "name": "MacBook Pro",
        "category": "ELECTRONIQUE",
        "description": "  Ordinateur portable Apple.  ",
        "price": "299.99"
      }
    }
  ]
}' | jq '.docs[0]._source | {name, category, description, price}'
# Attendu : category "electronique", description "Ordinateur portable Apple.", price 299.99


# ============================================
# EXERCICE 2 : Enrichissement + on_failure
# ============================================
echo ""
echo "=== Exercice 2 : Pipeline enrichissement + on_failure ==="

# on_failure sur le processor set : si le set échoue (champ manquant par ex.),
# le document est redirigé vers l index failed-products pour inspection
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-enrichissement" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Enrichissement et nettoyage",
  "processors": [
    {
      "set": {
        "field": "indexed_at",
        "value": "{{{_ingest.timestamp}}}",
        "on_failure": [
          { "set": { "field": "_index", "value": "failed-products" } }
        ]
      }
    },
    {
      "remove": {
        "field": "_tmp",
        "ignore_missing": true
      }
    }
  ]
}' | jq '{acknowledged}'

echo ""
echo "--- Indexation avec pipeline-enrichissement ---"
curl -s -X PUT "$BASE_URL/products/_doc/test-pipeline-001?pipeline=pipeline-enrichissement" \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "Vélo VTT Pro",
  "category": "sports",
  "price": 499.0,
  "_tmp": "draft"
}' | jq '{result, _id}'

echo ""
echo "--- Vérification : indexed_at présent, _tmp absent ---"
curl -s "$BASE_URL/products/_doc/test-pipeline-001" | jq '._source | {name, indexed_at, _tmp}'


# ============================================
# EXERCICE 3 : Processor conditionnel
# ============================================
echo ""
echo "=== Exercice 3 : Processor conditionnel ==="

# Painless est compilé côté serveur — performances correctes pour des conditions simples
# Ne pas y mettre de logique métier complexe (préférer le traitement en amont)
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-segment" \
  -H 'Content-Type: application/json' \
  -d '{
  "processors": [
    {
      "set": {
        "if":    "ctx.price != null && ctx.price > 500",
        "field": "segment",
        "value": "premium"
      }
    },
    {
      "set": {
        "if":    "ctx.price != null && ctx.price <= 500",
        "field": "segment",
        "value": "standard"
      }
    }
  ]
}' | jq '{acknowledged}'

echo ""
echo "--- Simulation : deux documents avec segments différents ---"
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-segment/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  "docs": [
    { "_source": { "name": "Laptop Pro", "price": 799 } },
    { "_source": { "name": "Souris USB",  "price": 49  } }
  ]
}' | jq '.docs[] | ._source | {name, price, segment}'
# Attendu : Laptop Pro → premium, Souris USB → standard


# ============================================
# EXERCICE 4 : Chaîner plusieurs pipelines
# ============================================
echo ""
echo "=== Exercice 4 : Pipeline maître — chaîner plusieurs pipelines ==="

# Le processor "pipeline" permet d appeler un autre pipeline depuis le courant.
# Avantage : pipelines petits, réutilisables, testables indépendamment.
# Ordre d exécution : pipeline-normalisation d abord, puis pipeline-enrichissement.
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-produits-complet" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Pipeline maître : normalisation puis enrichissement",
  "processors": [
    { "pipeline": { "name": "pipeline-normalisation"  } },
    { "pipeline": { "name": "pipeline-enrichissement" } }
  ]
}' | jq '{acknowledged}'

echo ""
echo "--- Test _simulate : toutes les transformations en un seul appel ---"
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
# Attendu : category "audio", description sans espaces, price 89.99, indexed_at présent, _tmp absent

echo ""
echo "--- Indexation réelle avec le pipeline maître ---"
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
echo "--- Vérification finale ---"
curl -s "$BASE_URL/products/_doc/test-master-001" \
  | jq '._source | {name, category, description, price, indexed_at}'

echo ""
echo "================================================"
echo " TP6 Solution terminée !"
echo "================================================"
