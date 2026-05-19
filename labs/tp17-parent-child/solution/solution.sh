#!/usr/bin/env bash
# TP17 — Solution complète : Parent-Child join field SpaceX
# Utilise curl + jq (pas de python3)

OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

echo "=== TP17 SOLUTION — Parent-Child join field SpaceX ==="
echo ""

# Nettoyer si nécessaire
echo "--- Nettoyage de l'index existant (si présent) ---"
curl -s -XDELETE "${OPENSEARCH_URL}/spacex-join" | jq '{acknowledged: .acknowledged}' 2>/dev/null || true
echo ""

# Créer l'index
echo "--- Création de l'index spacex-join ---"
curl -s -XPUT "${OPENSEARCH_URL}/spacex-join" \
  -H "Content-Type: application/json" \
  -d '{
    "mappings": {
      "properties": {
        "join_field": {
          "type": "join",
          "relations": {"rocket": "launch"}
        },
        "name": {"type": "keyword"},
        "country": {"type": "keyword"},
        "date_utc": {"type": "date"},
        "success": {"type": "boolean"},
        "flight_number": {"type": "integer"}
      }
    }
  }' | jq '.'

echo ""

# Parents
echo "--- Indexation des parents ---"
curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/rocket-falcon9" \
  -H "Content-Type: application/json" \
  -d '{"name": "Falcon 9", "country": "US", "join_field": {"name": "rocket"}}' \
  | jq '{result: .result, id: ._id}'

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/rocket-falconheavy" \
  -H "Content-Type: application/json" \
  -d '{"name": "Falcon Heavy", "country": "US", "join_field": {"name": "rocket"}}' \
  | jq '{result: .result, id: ._id}'

echo ""

# Enfants Falcon 9
echo "--- Indexation enfants Falcon 9 ---"
curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-1?routing=rocket-falcon9" \
  -H "Content-Type: application/json" \
  -d '{"name": "CRS-1", "date_utc": "2012-10-08T00:35:00.000Z", "success": true, "flight_number": 9, "join_field": {"name": "launch", "parent": "rocket-falcon9"}}' \
  | jq '{result: .result, id: ._id}'

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-2?routing=rocket-falcon9" \
  -H "Content-Type: application/json" \
  -d '{"name": "CRS-2", "date_utc": "2013-03-01T15:10:00.000Z", "success": true, "flight_number": 10, "join_field": {"name": "launch", "parent": "rocket-falcon9"}}' \
  | jq '{result: .result, id: ._id}'

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-3?routing=rocket-falcon9" \
  -H "Content-Type: application/json" \
  -d '{"name": "GPS III SV03", "date_utc": "2020-06-30T20:10:00.000Z", "success": true, "flight_number": 90, "join_field": {"name": "launch", "parent": "rocket-falcon9"}}' \
  | jq '{result: .result, id: ._id}'

echo ""

# Enfants Falcon Heavy
echo "--- Indexation enfants Falcon Heavy ---"
curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-4?routing=rocket-falconheavy" \
  -H "Content-Type: application/json" \
  -d '{"name": "Arabsat-6A", "date_utc": "2019-04-11T22:35:00.000Z", "success": true, "flight_number": 72, "join_field": {"name": "launch", "parent": "rocket-falconheavy"}}' \
  | jq '{result: .result, id: ._id}'

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-5?routing=rocket-falconheavy" \
  -H "Content-Type: application/json" \
  -d '{"name": "STP-2", "date_utc": "2019-06-25T06:30:00.000Z", "success": true, "flight_number": 74, "join_field": {"name": "launch", "parent": "rocket-falconheavy"}}' \
  | jq '{result: .result, id: ._id}'

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-6?routing=rocket-falconheavy" \
  -H "Content-Type: application/json" \
  -d '{"name": "USSF-44", "date_utc": "2022-11-01T13:41:00.000Z", "success": true, "flight_number": 168, "join_field": {"name": "launch", "parent": "rocket-falconheavy"}}' \
  | jq '{result: .result, id: ._id}'

echo ""

# Requêtes de vérification
echo "--- Requête has_child : fusées avec 3+ lancements réussis ---"
curl -s -XGET "${OPENSEARCH_URL}/spacex-join/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "has_child": {
        "type": "launch",
        "min_children": 3,
        "query": {"term": {"success": true}}
      }
    }
  }' | jq '.hits.total.value as $total | "Résultat: \($total) fusée(s) avec 3+ lancements réussis"'

echo ""

echo "--- Requête has_parent : lancements de fusées américaines ---"
curl -s -XGET "${OPENSEARCH_URL}/spacex-join/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "has_parent": {
        "parent_type": "rocket",
        "query": {"term": {"country": "US"}}
      }
    }
  }' | jq '.hits.total.value as $total | "Résultat: \($total) lancement(s) de fusées américaines"'

echo ""

echo "--- Test routing manquant (doit produire une erreur) ---"
RESULT=$(curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-bad" \
  -H "Content-Type: application/json" \
  -d '{"name": "Launch sans routing", "date_utc": "2023-01-01T00:00:00.000Z", "success": true, "flight_number": 200, "join_field": {"name": "launch", "parent": "rocket-falcon9"}}')
echo "$RESULT" | jq '{status: .status, error_type: .error.type}'

echo ""

echo "=== Solution terminée ==="
echo ""
echo "Compte total de documents :"
curl -s "${OPENSEARCH_URL}/spacex-join/_count" | jq '.count'
