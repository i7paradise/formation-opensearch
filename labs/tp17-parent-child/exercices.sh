#!/usr/bin/env bash
# TP17 — Exercices : Parent-Child join field SpaceX
# Utilise curl + jq (pas de python3)

OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

echo "=== TP17 — Parent-Child join field SpaceX ==="
echo ""

# Exercice 1 — Créer l'index avec mapping join
echo "--- Exercice 1 : Créer l'index spacex-join ---"
curl -s -XPUT "${OPENSEARCH_URL}/spacex-join" \
  -H "Content-Type: application/json" \
  -d @mapping-join.json | jq '.'

echo ""

# Exercice 2 — Indexer les parents (fusées)
echo "--- Exercice 2 : Indexer les parents (fusées) ---"

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/rocket-falcon9" \
  -H "Content-Type: application/json" \
  -d '{"name": "Falcon 9", "country": "US", "join_field": {"name": "rocket"}}' \
  | jq '{result: .result, id: ._id}'

curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/rocket-falconheavy" \
  -H "Content-Type: application/json" \
  -d '{"name": "Falcon Heavy", "country": "US", "join_field": {"name": "rocket"}}' \
  | jq '{result: .result, id: ._id}'

echo ""

# Exercice 3 — Indexer les enfants (lancements) avec routing obligatoire
echo "--- Exercice 3 : Indexer les enfants (lancements) avec routing ---"

for i in \
  "launch-1|rocket-falcon9|CRS-1|2012-10-08T00:35:00.000Z|true|9" \
  "launch-2|rocket-falcon9|CRS-2|2013-03-01T15:10:00.000Z|true|10" \
  "launch-3|rocket-falcon9|GPS III SV03|2020-06-30T20:10:00.000Z|true|90" \
  "launch-4|rocket-falconheavy|Arabsat-6A|2019-04-11T22:35:00.000Z|true|72" \
  "launch-5|rocket-falconheavy|STP-2|2019-06-25T06:30:00.000Z|true|74" \
  "launch-6|rocket-falconheavy|USSF-44|2022-11-01T13:41:00.000Z|true|168"
do
  IFS='|' read -r doc_id parent_id name date success flight <<< "$i"
  curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/${doc_id}?routing=${parent_id}" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${name}\", \"date_utc\": \"${date}\", \"success\": ${success}, \"flight_number\": ${flight}, \"join_field\": {\"name\": \"launch\", \"parent\": \"${parent_id}\"}}" \
    | jq "{result: .result, id: ._id}"
done

echo ""

# Exercice 4 — Requête has_child : fusées avec 3+ lancements réussis
echo "--- Exercice 4 : has_child — fusées avec 3+ lancements réussis ---"
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
  }' | jq '.hits.hits[] | {id: ._id, name: ._source.name, country: ._source.country}'

echo ""

# Exercice 5 — Requête has_parent : lancements de fusées américaines
echo "--- Exercice 5 : has_parent — lancements de fusées américaines ---"
curl -s -XGET "${OPENSEARCH_URL}/spacex-join/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "has_parent": {
        "parent_type": "rocket",
        "query": {"term": {"country": "US"}}
      }
    }
  }' | jq '.hits.hits[] | {id: ._id, name: ._source.name, flight_number: ._source.flight_number, success: ._source.success}'

echo ""

# Exercice 6 — Tester l'erreur de routing manquant
echo "--- Exercice 6 : Erreur routing manquant (comportement attendu) ---"
curl -s -XPUT "${OPENSEARCH_URL}/spacex-join/_doc/launch-bad" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Launch sans routing",
    "date_utc": "2023-01-01T00:00:00.000Z",
    "success": true,
    "flight_number": 200,
    "join_field": {"name": "launch", "parent": "rocket-falcon9"}
  }' | jq '{error: .error.reason, type: .error.type}'

echo ""
echo "=== Exercices terminés ==="
