#!/usr/bin/env bash
# TP16 — Solution : Vérification Anomaly Detection SpaceX
# Utilise curl + jq (pas de python3)

OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

echo "=== TP16 — Vérification Anomaly Detection SpaceX ==="
echo ""

# 1. Vérifier que l'index spacex-launches existe et contient des données
echo "--- 1. Compte de documents dans spacex-launches ---"
curl -s "${OPENSEARCH_URL}/spacex-launches/_count" | jq '.count'

echo ""

# 2. Injecter les données d'anomalie si nécessaire
echo "--- 2. Injection des données d'anomalie (optionnel si index insuffisant) ---"
echo "Commande pour injecter bulk-anomalies.ndjson :"
echo "  curl -XPOST ${OPENSEARCH_URL}/spacex-launches/_bulk \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       --data-binary @bulk-anomalies.ndjson"

echo ""

# 3. Vérifier l'index des résultats d'anomalie (créé par OpenSearch après analyse)
echo "--- 3. Index de résultats anomaly detection ---"
curl -s "${OPENSEARCH_URL}/_cat/indices/.opendistro-anomaly-results*?v&h=index,docs.count,store.size" 2>/dev/null \
  || echo "Pas encore d'index de résultats (l'analyse historique n'a pas encore été lancée)"

echo ""

# 4. Afficher les détecteurs existants via API
echo "--- 4. Détecteurs d'anomalies configurés ---"
curl -s "${OPENSEARCH_URL}/_plugins/_anomaly_detection/detectors/_search" \
  -H "Content-Type: application/json" \
  -d '{"query": {"match_all": {}}}' \
  | jq '.hits.hits[] | {id: ._id, name: ._source.name, indices: ._source.indices}'

echo ""

# 5. Vérifier la plage de dates des données SpaceX
echo "--- 5. Plage de dates des données SpaceX ---"
curl -s "${OPENSEARCH_URL}/spacex-launches/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "min_date": {"min": {"field": "@timestamp"}},
      "max_date": {"max": {"field": "@timestamp"}},
      "total_flights": {"value_count": {"field": "flight_number"}},
      "max_flight_number": {"max": {"field": "flight_number"}}
    }
  }' | jq '.aggregations'

echo ""

# 6. Vérifier les documents avec flight_number anormalement élevé
echo "--- 6. Documents avec flight_number > 500 (anomalies injectées) ---"
curl -s "${OPENSEARCH_URL}/spacex-launches/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {"range": {"flight_number": {"gt": 500}}},
    "_source": ["name", "flight_number", "date_utc", "@timestamp"],
    "size": 10
  }' | jq '.hits.hits[] | ._source'

echo ""
echo "=== Vérification terminée ==="
echo ""
echo "RAPPEL : Pour créer le détecteur, utilisez OpenSearch Dashboards :"
echo "  1. http://localhost:5601"
echo "  2. OpenSearch Plugins > Anomaly Detection > Create detector"
echo "  3. Index: spacex-launches, Field: flight_number, Interval: 1 month, Shingle size: 8"
