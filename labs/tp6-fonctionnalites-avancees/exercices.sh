#!/bin/bash
# TP4 — Fonctionnalités Avancées OpenSearch
# Complétez les sections marquées # TODO

BASE_URL="http://localhost:9200"

echo "=== Exercice 1 : Ingest Pipeline ==="

# TODO: Créer le pipeline pipeline-produits
# Processeurs requis:
#   1. lowercase sur le champ "category"
#   2. trim sur le champ "description"
#   3. set pour ajouter "indexed_at" avec "{{_ingest.timestamp}}"
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-produits" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: Compléter la définition du pipeline
}'

echo ""
echo "--- Test avec _simulate ---"
# TODO: Tester le pipeline avec un document exemple
# Utiliser POST _ingest/pipeline/pipeline-produits/_simulate
# avec un document exemple ayant category="ELECTRONIQUE" et une description avec des espaces
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-produits/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: Ajouter le document de test
}'

echo ""
echo "=== Exercice 2 : Analyseur Français ==="

# TODO: Créer l'index products-v2 avec l'analyseur french_custom
# L'analyseur doit contenir:
#   - tokenizer: standard
#   - filters: lowercase, asciifolding, french_stop (_french_), french_stemmer (language: french)
# Ajouter le champ "name" mappé avec l'analyseur french_custom
curl -s -X PUT "$BASE_URL/products-v2" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: Définir settings.analysis et mappings.properties
}'

echo ""
echo "--- Test de l'analyseur ---"
# TODO: Tester l'analyseur avec la phrase "Vélos électriques d'entrée de gamme"
curl -s -X POST "$BASE_URL/products-v2/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: Utiliser l'analyseur french_custom sur le texte ci-dessus
}'

echo ""
echo "=== Exercice 3 : Réindexation ==="

# TODO: Réindexer products vers products-v2
curl -s -X POST "$BASE_URL/_reindex" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: source: products, dest: products-v2
}'

# Vérification du count
echo "Count products-v2:"
curl -s "$BASE_URL/products-v2/_count"

echo ""
echo "=== Exercice 4 : Completion Suggester ==="

# TODO: Chercher avec autocomplétion - préfixe "ordi"
curl -s -X POST "$BASE_URL/products-v2/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "suggest": {
    "produit-suggest": {
      "prefix": "ordi",
      # TODO: Compléter avec completion field name_suggest et fuzzy fuzziness 1
    }
  }
}'

echo ""
echo "=== Exercice 5 : Highlighting ==="

# TODO: Recherche avec highlighting sur name et description
curl -s -X POST "$BASE_URL/products-v2/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "query": {
    "match": { "name": "ordinateur" }
  },
  # TODO: Ajouter le highlighting avec balises <mark></mark> et fragment_size 150
}'

echo ""
echo "=== Exercice 6 : Recherche Géographique ==="

# TODO: Trouver les magasins dans un rayon de 5km autour de Paris
# Paris: lat 48.8566, lon 2.3522
# Trier par distance croissante
curl -s -X POST "$BASE_URL/stores/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  # TODO: geo_distance query + _geo_distance sort
}'

echo ""
echo "=== TP Bonus : Voulez-vous dire ? ==="

# TODO: Term suggester pour corriger "ordenateur"
curl -s -X POST "$BASE_URL/products-v2/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "suggest": {
    "correction": {
      "text": "ordenateur",
      # TODO: term suggester sur le champ name avec suggest_mode missing
    }
  }
}'

echo ""
echo "=== TP4 terminé ! ==="
