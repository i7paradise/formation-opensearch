#!/bin/bash
# TP11 — Reindex + ISM

BASE_URL="http://localhost:9200"

echo "=== Exercice 1 : Créer un alias ==="
curl -s -X POST "$BASE_URL/_aliases" \
  -H 'Content-Type: application/json' \
  -d '{"actions":[{"add":{"index":"products","alias":"products-current","is_write_index":true}}]}'

echo ""
echo "=== TODO : Créer products-v2 avec mapping amélioré ==="
# TODO : PUT /products-v2 avec 3 shards et analyseur french sur description

echo ""
echo "=== TODO : Reindex products → products-v2 ==="
# TODO : POST /_reindex

echo ""
echo "=== TODO : Vérifier le nombre de documents ==="
# TODO : GET /_cat/indices/products*?v

echo ""
echo "=== TODO : Basculer l'alias ==="
# TODO : POST /_aliases avec remove + add atomique

echo ""
echo "=== TODO : Créer la politique ISM ==="
# TODO : PUT /_plugins/_ism/policies/logs-lifecycle
