#!/bin/bash
# TP9 — Agrégations avancées

BASE_URL="http://localhost:9200"

echo "=== Exercice 1 : Statistiques de base ==="
curl -s -X GET "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"size": 0, "aggs": {"prix_stats": {"stats": {"field": "price"}}}}' | python3 -m json.tool

echo ""
echo "=== TODO : Exercice 2 — Agrégations bucket ==="
# TODO : terms sur category
# TODO : range sur price (4 plages)
# TODO : histogram avec interval 100

echo ""
echo "=== TODO : Exercice 3 — Agrégations imbriquées ==="
# TODO : par_categorie + prix_moyen + note_moyenne
# TODO : top_hits par catégorie

echo ""
echo "=== TODO : Exercice 4 — Pipeline aggregations ==="
# TODO : max_bucket
# TODO : filters (en_stock vs rupture)
