#!/bin/bash
# TP7 — Solution complète — Analyseur français

BASE_URL="http://localhost:9200"

echo "================================================"
echo " TP7 — Solution : Analyseur français"
echo "================================================"


# ============================================
# EXERCICE 1 : Constater le problème
# ============================================
echo ""
echo "=== Exercice 1 : Constater le problème ==="

echo "--- velo (sans accent) ---"
curl -s -X POST "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "velo" } }, "size": 0 }' \
  | jq '"velo → \(.hits.total.value) résultats"'

echo "--- vélos (avec accent) ---"
curl -s -X POST "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "vélos" } }, "size": 0 }' \
  | jq '"vélos → \(.hits.total.value) résultats"'

# Observation : "velo" retourne 0 car l analyseur standard ne supprime pas les accents
# et ne stemmatise pas. "Vélos" ≠ "velo" pour le moteur.


# ============================================
# EXERCICE 2 : Comprendre la cause
# ============================================
echo ""
echo "=== Exercice 2 : Comprendre la cause ==="

echo "--- Analyseur standard — tokens produits ---"
curl -s -X POST "$BASE_URL/products/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  "analyzer": "standard",
  "text": "Vélos électriques d'\''entrée de gamme"
}' | jq '[.tokens[].token]'
# → ["vélos", "électriques", "d", "entrée", "de", "gamme"]
# "velo" n est pas là : accents conservés, stop words gardés, pas de stemming

echo ""
echo "--- Analyseur french (built-in) — tokens produits ---"
curl -s -X POST "$BASE_URL/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  "analyzer": "french",
  "text": "Vélos électriques d'\''entrée de gamme"
}' | jq '[.tokens[].token]'
# → ["velo", "electr", "entré", "gam"] — stop words supprimés, stemming appliqué


# ============================================
# EXERCICE 3 : Créer l analyseur personnalisé
# ============================================
echo ""
echo "=== Exercice 3 : Créer products-fr avec analyseur french_custom ==="

curl -s -X DELETE "$BASE_URL/products-fr" > /dev/null 2>&1

# Pipeline de l analyseur :
# 1. standard tokenizer : découpe sur espaces/ponctuation
# 2. lowercase         : "Vélos" → "vélos"
# 3. asciifolding      : "vélos" → "velos" (suppression des accents)
# 4. french_stop       : supprime "de", "le", "la", "d", etc.
# 5. french_stemmer    : "velos" → "velo", "electriques" → "electr"
# Résultat : une seule forme canonique pour "Vélos", "vélo", "velo", "vélos"
curl -s -X PUT "$BASE_URL/products-fr" \
  -H 'Content-Type: application/json' \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "analysis": {
      "filter": {
        "french_stop": {
          "type":      "stop",
          "stopwords": "_french_"
        },
        "french_stemmer": {
          "type":     "stemmer",
          "language": "french"
        }
      },
      "analyzer": {
        "french_custom": {
          "type":      "custom",
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "asciifolding",
            "french_stop",
            "french_stemmer"
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": {
        "type":     "text",
        "analyzer": "french_custom",
        "fields":   { "keyword": { "type": "keyword" } }
      },
      "description":    { "type": "text",    "analyzer": "french_custom" },
      "category":       { "type": "keyword" },
      "sub_category":   { "type": "keyword" },
      "brand":          { "type": "keyword" },
      "price":          { "type": "float"   },
      "original_price": { "type": "float"   },
      "in_stock":       { "type": "boolean" },
      "stock_quantity": { "type": "integer" },
      "rating":         { "type": "float"   },
      "reviews_count":  { "type": "integer" },
      "tags":           { "type": "keyword" },
      "created_at":     { "type": "date"    },
      "updated_at":     { "type": "date"    },
      "seller":         { "type": "keyword" },
      "color":          { "type": "keyword" }
    }
  }
}' | jq '{acknowledged}'

echo ""
echo "--- Vérification analyseur : tokens de 'Vélos électriques d entrée de gamme' ---"
curl -s -X POST "$BASE_URL/products-fr/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  "analyzer": "french_custom",
  "text": "Vélos électriques d'\''entrée de gamme"
}' | jq '[.tokens[].token]'
# Attendu : ["velo", "electr", ...] — "de", "d", "entrée" supprimés ou stémmatisés


# ============================================
# EXERCICE 4 : Réindexer
# ============================================
echo ""
echo "=== Exercice 4 : Réindexation products → products-fr ==="

# _reindex copie les documents sources tels quels
# L analyseur french_custom s applique à l indexation dans products-fr
curl -s -X POST "$BASE_URL/_reindex?wait_for_completion=true" \
  -H 'Content-Type: application/json' \
  -d '{
  "source": { "index": "products"    },
  "dest":   { "index": "products-fr" }
}' | jq '{created, total}'

echo ""
echo "--- Vérification des counts ---"
echo -n "products      : "
curl -s "$BASE_URL/products/_count" | jq '.count'
echo -n "products-fr   : "
curl -s "$BASE_URL/products-fr/_count" | jq '.count'


# ============================================
# EXERCICE 5 : velo trouve des vélos
# ============================================
echo ""
echo "=== Exercice 5 : La même requête, deux résultats différents ==="

echo "--- AVANT : velo dans products (analyseur standard) ---"
curl -s -X POST "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "velo" } }, "size": 0 }' \
  | jq '"velo dans products    → \(.hits.total.value) résultats"'

echo ""
echo "--- APRÈS : velo dans products-fr (analyseur french_custom) ---"
curl -s -X POST "$BASE_URL/products-fr/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "velo" } }, "size": 5 }' \
  | jq '"velo dans products-fr → \(.hits.total.value) résultats"',
       '.hits.hits[] | ._source | {name, category}'

echo ""
echo "--- Bonus : electrique (sans accent) matche électrique ---"
curl -s -X POST "$BASE_URL/products-fr/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "electrique" } }, "size": 0 }' \
  | jq '"electrique (sans accent) → \(.hits.total.value) résultats"'

echo ""
echo "--- Bonus : ordinateur matche ordinateurs ---"
curl -s -X POST "$BASE_URL/products-fr/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "ordinateur" } }, "size": 0 }' \
  | jq '"ordinateur (singulier) → \(.hits.total.value) résultats"'

echo ""
echo "================================================"
echo " TP7 Solution terminée !"
echo "================================================"
