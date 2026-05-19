#!/bin/bash
# TP11 Solution

BASE_URL="http://localhost:9200"

echo "=== Alias products-current ==="
curl -s -X POST "$BASE_URL/_aliases" -H 'Content-Type: application/json' \
  -d '{"actions":[{"add":{"index":"products","alias":"products-current","is_write_index":true}}]}' 
echo ""
echo "=== Créer products-v2 ==="
curl -s -X DELETE "$BASE_URL/products-v2" 2>/dev/null
curl -s -X PUT "$BASE_URL/products-v2" -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":3,"number_of_replicas":1},"mappings":{"properties":{"name":{"type":"text","fields":{"keyword":{"type":"keyword"}}},"description":{"type":"text","analyzer":"french"},"category":{"type":"keyword"},"price":{"type":"float"},"in_stock":{"type":"boolean"},"rating":{"type":"float"},"created_at":{"type":"date"},"tags":{"type":"keyword"}}}}' 
echo ""
echo "=== Reindex ==="
curl -s -X POST "$BASE_URL/_reindex?wait_for_completion=true" -H 'Content-Type: application/json' \
  -d '{"source":{"index":"products"},"dest":{"index":"products-v2"}}' \
  | jq -r '"Copied: \((.created // 0) + (.updated // 0)) Failures: \(.failures | length)"' 2>/dev/null

echo ""
echo "=== Vérifier counts ==="
curl -s "$BASE_URL/_cat/indices/products*?v&h=index,docs.count"

echo ""
echo "=== Basculer alias ==="
curl -s -X POST "$BASE_URL/_aliases" -H 'Content-Type: application/json' \
  -d '{"actions":[{"remove":{"index":"products","alias":"products-current"}},{"add":{"index":"products-v2","alias":"products-current","is_write_index":true}}]}' 
echo ""
echo "=== Politique ISM ==="
curl -s -X PUT "$BASE_URL/_plugins/_ism/policies/logs-lifecycle" -H 'Content-Type: application/json' \
  -d '{"policy":{"description":"Lifecycle logs","default_state":"hot","states":[{"name":"hot","actions":[{"rollover":{"min_doc_count":1000,"min_index_age":"1d"}}],"transitions":[{"state_name":"warm","conditions":{"min_index_age":"2d"}}]},{"name":"warm","actions":[{"replica_count":{"number_of_replicas":0}},{"force_merge":{"max_num_segments":1}}],"transitions":[{"state_name":"delete","conditions":{"min_index_age":"7d"}}]},{"name":"delete","actions":[{"delete":{}}],"transitions":[]}]}}' 