#!/bin/bash
# TP9 Solution

BASE_URL="http://localhost:9200"

echo "=== Stats prix ==="
curl -s -X GET "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"stats":{"stats":{"field":"price"}},"pct":{"percentiles":{"field":"price","percents":[25,50,75,95]}}}}' | python3 -m json.tool

echo ""
echo "=== Distribution catégories ==="
curl -s -X GET "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"cats":{"terms":{"field":"category","size":20}}}}' | python3 -m json.tool

echo ""
echo "=== Range prix ==="
curl -s -X GET "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"plages":{"range":{"field":"price","ranges":[{"key":"<50","to":50},{"key":"50-200","from":50,"to":200},{"key":"200-500","from":200,"to":500},{"key":">500","from":500}]}}}}' | python3 -m json.tool

echo ""
echo "=== Prix moyen par catégorie + top produits ==="
curl -s -X GET "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"cats":{"terms":{"field":"category","size":10},"aggs":{"avg_price":{"avg":{"field":"price"}},"top":{"top_hits":{"sort":[{"rating":{"order":"desc"}}],"_source":["name","price","rating"],"size":2}}}}}}' | python3 -m json.tool

echo ""
echo "=== Catégorie la plus chère (max_bucket) ==="
curl -s -X GET "$BASE_URL/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{"size":0,"aggs":{"cats":{"terms":{"field":"category","size":20},"aggs":{"avg_price":{"avg":{"field":"price"}}}},"top_cat":{"max_bucket":{"buckets_path":"cats>avg_price"}}}}' | python3 -m json.tool
