#!/bin/bash
# TP7 — Analyseur français
# Complétez les sections marquées # TODO

BASE_URL="http://localhost:9200"

echo "================================================"
echo " TP7 — Analyseur français"
echo "================================================"


echo ""
echo "=== Exercice 1 : Constater le problème ==="
echo "--- Recherche 'velo' dans products (résultat attendu : 0) ---"

# TODO: Rechercher "velo" dans le champ name de l index products
curl -s -X POST "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: query match sur name: "velo"
  "size": 0
}' | jq '"velo → \(.hits.total.value) résultats"'

echo ""
echo "--- Recherche 'vélos' (avec accent) ---"
# TODO: même requête avec "vélos"
curl -s -X POST "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: query match sur name: "vélos"
  "size": 0
}' | jq '"vélos → \(.hits.total.value) résultats"'


echo ""
echo "=== Exercice 2 : Comprendre la cause — _analyze ==="
echo "--- Analyseur standard (actuel) ---"

# TODO: Analyser "Vélos électriques d entrée de gamme" avec l analyseur standard
curl -s -X POST "$BASE_URL/products/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  "analyzer": "standard",
  # TODO: texte à analyser
}' | jq '[.tokens[].token]'

echo ""
echo "--- Analyseur french (built-in) --- qu est-ce qui change ? ---"
# TODO: même texte avec l analyseur "french"
curl -s -X POST "$BASE_URL/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  "analyzer": "french",
  # TODO: même texte
}' | jq '[.tokens[].token]'


echo ""
echo "=== Exercice 3 : Créer l analyseur français personnalisé ==="

curl -s -X DELETE "$BASE_URL/products-fr" > /dev/null 2>&1

# TODO: Créer l index products-fr avec :
#   settings.analysis.filter.french_stop  → type stop, stopwords _french_
#   settings.analysis.filter.french_stemmer → type stemmer, language french
#   settings.analysis.analyzer.french_custom → tokenizer standard,
#     filters [lowercase, asciifolding, french_stop, french_stemmer]
#   mappings.properties.name → type text, analyzer french_custom
curl -s -X PUT "$BASE_URL/products-fr" \
  -H 'Content-Type: application/json' \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "analysis": {
      "filter": {
        "french_stop": {
          # TODO
        },
        "french_stemmer": {
          # TODO
        }
      },
      "analyzer": {
        "french_custom": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": [
            # TODO: liste des filters dans l ordre
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": {
        # TODO: type text + analyzer french_custom
      },
      "description": { "type": "text", "analyzer": "french_custom" },
      "category":    { "type": "keyword" },
      "price":       { "type": "float" },
      "in_stock":    { "type": "boolean" },
      "rating":      { "type": "float" }
    }
  }
}' | jq '{acknowledged}'

echo ""
echo "--- Vérification : tokens de 'Vélos électriques d entrée de gamme' ---"
# TODO: tester avec POST products-fr/_analyze, analyzer french_custom
curl -s -X POST "$BASE_URL/products-fr/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: analyzer french_custom + texte
}' | jq '[.tokens[].token]'
# Attendu : ["velo", "electr", "entré", "gam"] — sans "de", "d", "de"


echo ""
echo "=== Exercice 4 : Réindexer products → products-fr ==="

# TODO: Réindexer products vers products-fr
curl -s -X POST "$BASE_URL/_reindex?wait_for_completion=true" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: source products, dest products-fr
}' | jq '{created, total}'

echo ""
echo "--- Vérification des counts ---"
echo -n "products      : "
curl -s "$BASE_URL/products/_count" | jq '.count'
echo -n "products-fr   : "
curl -s "$BASE_URL/products-fr/_count" | jq '.count'


echo ""
echo "=== Exercice 5 : velo trouve des vélos ==="

echo "--- products (sans analyseur) ---"
# TODO: query velo sur products
curl -s -X POST "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "velo" } }, "size": 0 }' \
  | jq '"velo dans products    → \(.hits.total.value) résultats"'

echo ""
echo "--- products-fr (avec analyseur) ---"
# TODO: même query sur products-fr
curl -s -X POST "$BASE_URL/products-fr/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "velo" } }, "size": 3 }' \
  | jq '"velo dans products-fr → \(.hits.total.value) résultats"',
       '.hits.hits[] | ._source | {name, category}'

echo ""
echo "--- Bonus : electrique (sans accent) matche électrique ---"
curl -s -X POST "$BASE_URL/products-fr/_search" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "name": "electrique" } }, "size": 0 }' \
  | jq '"electrique → \(.hits.total.value) résultats"'

echo ""
echo "=== TP7 terminé ! ==="
