#!/bin/bash
# =============================================================================
# TP2 — SOLUTION COMPLÈTE
# CRUD & API OpenSearch — Catalogue produits e-commerce
# =============================================================================
# Ce fichier contient toutes les réponses aux TODOs de exercices.sh
# avec des commentaires expliquant pourquoi chaque solution fonctionne
# =============================================================================

BASE_URL="http://localhost:9200"
INDEX="products"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_step() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

echo_ok() {
  echo -e "${GREEN}[OK]${NC} $1"
}

# =============================================================================
# EXERCICE 1 — Mapping complet (déjà fourni dans exercices.sh — rappel)
# =============================================================================

echo_step "EXERCICE 1 — Création de l'index avec mapping"

# Suppression propre
curl -s -X DELETE "$BASE_URL/$INDEX" > /dev/null
sleep 1

# Le mapping utilise :
# - "text" pour les champs de recherche full-text (name, description)
# - "keyword" pour les champs filtrables/agrégables (category, brand, color...)
# - "float" pour les prix et notes décimales
# - "integer" pour les quantités entières
# - "boolean" pour les booléens (in_stock)
# - "date" pour les timestamps ISO 8601
#
# ASTUCE : name a un double mapping text + keyword (via "fields")
# Cela permet la recherche full-text ET les agrégations exactes sur ce champ.

curl -s -X PUT "$BASE_URL/$INDEX" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "refresh_interval": "1s"
    },
    "mappings": {
      "properties": {
        "name": {
          "type": "text",
          "fields": {
            "keyword": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "description": {
          "type": "text"
        },
        "category": {
          "type": "keyword"
        },
        "sub_category": {
          "type": "keyword"
        },
        "brand": {
          "type": "keyword"
        },
        "price": {
          "type": "float"
        },
        "original_price": {
          "type": "float"
        },
        "currency": {
          "type": "keyword"
        },
        "in_stock": {
          "type": "boolean"
        },
        "stock_quantity": {
          "type": "integer"
        },
        "rating": {
          "type": "float"
        },
        "reviews_count": {
          "type": "integer"
        },
        "tags": {
          "type": "keyword"
        },
        "created_at": {
          "type": "date"
        },
        "updated_at": {
          "type": "date"
        },
        "seller": {
          "type": "keyword"
        },
        "weight_kg": {
          "type": "float"
        },
        "color": {
          "type": "keyword"
        }
      }
    }
  }'

echo_ok "Index $INDEX créé avec mapping explicite"

# =============================================================================
# EXERCICE 2 — Indexation manuelle des 5 produits
# =============================================================================

echo_step "EXERCICE 2 — Indexation manuelle des 5 produits"

# PRODUIT 1 — Smartphone
# PUT /products/_doc/1 : crée ou remplace complètement le document avec l'ID 1.
# Si le document existe déjà, il est remplacé entièrement et _version est incrémenté.
echo "Indexation du produit 1 (Smartphone)..."
curl -s -X PUT "$BASE_URL/$INDEX/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Smartphone XPhone Pro 256Go",
    "description": "Smartphone haut de gamme avec écran AMOLED 6.7 pouces, processeur octa-core et triple capteur photo 108MP",
    "category": "Électronique",
    "sub_category": "Smartphones",
    "brand": "TechBrand",
    "price": 899.99,
    "original_price": 1099.99,
    "currency": "EUR",
    "in_stock": true,
    "stock_quantity": 42,
    "rating": 4.5,
    "reviews_count": 1234,
    "tags": ["smartphone", "5G", "AMOLED", "256Go"],
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-03-20T14:00:00Z",
    "seller": "TechShop",
    "weight_kg": 0.195,
    "color": "Noir"
  }'

echo ""
echo "Indexation du produit 2 (Ordinateur portable)..."
curl -s -X PUT "$BASE_URL/$INDEX/_doc/2" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Ordinateur Portable UltraBook 15",
    "description": "Laptop ultra-fin 15 pouces, Intel Core i7, 16Go RAM, SSD 512Go, idéal pour les professionnels",
    "category": "Électronique",
    "sub_category": "Ordinateurs portables",
    "brand": "CompuPro",
    "price": 1299.00,
    "original_price": 1499.00,
    "currency": "EUR",
    "in_stock": true,
    "stock_quantity": 15,
    "rating": 4.3,
    "reviews_count": 567,
    "tags": ["laptop", "i7", "SSD", "ultrabook"],
    "created_at": "2024-02-01T09:00:00Z",
    "updated_at": "2024-03-15T11:00:00Z",
    "seller": "InfoStore",
    "weight_kg": 1.8,
    "color": "Argent"
  }'

echo ""
echo "Indexation du produit 3 (Casque audio)..."
curl -s -X PUT "$BASE_URL/$INDEX/_doc/3" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Casque Audio Sans Fil SoundMax",
    "description": "Casque Bluetooth avec réduction de bruit active, autonomie 30h, recharge rapide USB-C",
    "category": "Électronique",
    "sub_category": "Audio",
    "brand": "SoundMax",
    "price": 199.99,
    "original_price": 249.99,
    "currency": "EUR",
    "in_stock": true,
    "stock_quantity": 89,
    "rating": 4.7,
    "reviews_count": 2345,
    "tags": ["casque", "bluetooth", "reduction-bruit", "sans-fil"],
    "created_at": "2024-01-20T14:00:00Z",
    "updated_at": "2024-03-10T09:30:00Z",
    "seller": "AudioWorld",
    "weight_kg": 0.285,
    "color": "Blanc"
  }'

echo ""
echo "Indexation du produit 4 (Livre)..."
curl -s -X PUT "$BASE_URL/$INDEX/_doc/4" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Guide complet du Machine Learning",
    "description": "Apprentissage du Machine Learning de A à Z, avec exemples pratiques en Python et TensorFlow",
    "category": "Livres",
    "sub_category": "Informatique",
    "brand": "ÉditionsData",
    "price": 39.90,
    "original_price": 39.90,
    "currency": "EUR",
    "in_stock": true,
    "stock_quantity": 200,
    "rating": 4.6,
    "reviews_count": 445,
    "tags": ["machine-learning", "python", "ia", "données"],
    "created_at": "2023-09-01T00:00:00Z",
    "updated_at": "2023-09-01T00:00:00Z",
    "seller": "LibraireNet",
    "weight_kg": 0.95,
    "color": "N/A"
  }'

echo ""
echo "Indexation du produit 5 (Montre connectée — en rupture)..."
curl -s -X PUT "$BASE_URL/$INDEX/_doc/5" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Montre Connectée FitWatch Ultra",
    "description": "Smartwatch avec GPS intégré, suivi cardiaque continu, étanche 50m, autonomie 7 jours",
    "category": "Montres & Accessoires",
    "sub_category": "Montres connectées",
    "brand": "FitTech",
    "price": 349.00,
    "original_price": 399.00,
    "currency": "EUR",
    "in_stock": false,
    "stock_quantity": 0,
    "rating": 4.4,
    "reviews_count": 892,
    "tags": ["smartwatch", "GPS", "fitness", "etanche"],
    "created_at": "2024-03-01T00:00:00Z",
    "updated_at": "2024-03-18T16:00:00Z",
    "seller": "SportElec",
    "weight_kg": 0.042,
    "color": "Bleu"
  }'

# Rafraîchissement pour rendre les docs immédiatement visibles
curl -s -X POST "$BASE_URL/$INDEX/_refresh" > /dev/null
echo_ok "5 produits indexés et index rafraîchi"

# =============================================================================
# EXERCICE 3 — Lire, mettre à jour, supprimer
# =============================================================================

echo_step "EXERCICE 3 — CRUD"

# SOLUTION : Récupérer le produit par son ID
# GET /products/_doc/1 retourne le document complet avec les métadonnées :
# - _index : l'index d'appartenance
# - _id    : l'identifiant du document
# - _version : le numéro de version (incrémenté à chaque modification)
# - _source : les données du document
# - found  : true si le document existe
echo "Solution : Récupération du smartphone (ID 1)"
curl -s "$BASE_URL/$INDEX/_doc/1"

echo ""

# SOLUTION : Mise à jour partielle du prix
# POST /products/_update/1 avec {"doc": {...}} effectue un MERGE partiel :
# seuls les champs fournis sont modifiés. Le reste du document est conservé.
# C'est différent de PUT qui remplacerait tout le document.
echo "Solution : Mise à jour du prix du smartphone à 799.99€"
curl -s -X POST "$BASE_URL/$INDEX/_update/1" \
  -H 'Content-Type: application/json' \
  -d '{
    "doc": {
      "price": 799.99,
      "updated_at": "2024-04-01T00:00:00Z"
    }
  }'

echo ""
echo "Vérification du nouveau prix :"
curl -s "$BASE_URL/$INDEX/_doc/1" | grep -E '"price"|"updated_at"|"_version"'

echo ""

# Mise à jour scriptée (appliquée dans exercices.sh également)
echo "Script Painless : remise 10% sur le casque (ID 3)"
curl -s -X POST "$BASE_URL/$INDEX/_update/3" \
  -H 'Content-Type: application/json' \
  -d '{
    "script": {
      "source": "ctx._source.price = Math.round(ctx._source.price * 0.9 * 100) / 100.0; ctx._source.updated_at = params.now",
      "lang": "painless",
      "params": {
        "now": "2024-04-01T00:00:00Z"
      }
    }
  }'

echo ""
echo "Prix après remise (199.99 * 0.9 = 179.99€) :"
curl -s "$BASE_URL/$INDEX/_doc/3" | grep '"price"'

echo ""

# SOLUTION : Supprimer le produit ID 5
# DELETE /products/_doc/5 supprime définitivement le document.
# La réponse contient "result": "deleted" si le document existait,
# ou "result": "not_found" s'il n'existait pas.
echo "Solution : Suppression de la montre connectée (ID 5 — en rupture)"
curl -s -X DELETE "$BASE_URL/$INDEX/_doc/5"

echo ""
echo "Vérification : le document ID 5 ne doit plus exister (found: false)"
curl -s "$BASE_URL/$INDEX/_doc/5"

# =============================================================================
# EXERCICE 4 — Bulk API
# =============================================================================

echo_step "EXERCICE 4 — Bulk API"

BULK_FILE="../../data/products-bulk.ndjson"

if [ ! -f "$BULK_FILE" ]; then
  echo "Fichier $BULK_FILE non trouvé. Création d'un exemple minimal pour démonstration..."
  # Créer un mini fichier de démonstration
  DEMO_FILE="/tmp/products-demo.ndjson"
  cat > "$DEMO_FILE" << 'NDJSON'
{"index":{"_index":"products","_id":"100"}}
{"name":"Produit Demo 100","description":"Produit de démonstration","category":"Électronique","sub_category":"Accessoires","brand":"DemoBrand","price":49.99,"original_price":59.99,"currency":"EUR","in_stock":true,"stock_quantity":100,"rating":4.0,"reviews_count":50,"tags":["demo"],"created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-01T00:00:00Z","seller":"DemoShop","weight_kg":0.1,"color":"Noir"}
{"index":{"_index":"products","_id":"101"}}
{"name":"Produit Demo 101","description":"Autre produit de démonstration","category":"Vêtements","sub_category":"Sport","brand":"SportBrand","price":79.99,"original_price":99.99,"currency":"EUR","in_stock":true,"stock_quantity":200,"rating":4.2,"reviews_count":120,"tags":["sport","demo"],"created_at":"2024-01-02T00:00:00Z","updated_at":"2024-01-02T00:00:00Z","seller":"SportShop","weight_kg":0.3,"color":"Bleu"}
NDJSON
  BULK_FILE="$DEMO_FILE"
  echo "Fichier de démo créé : $BULK_FILE"
fi

# La clé de la solution Bulk API :
# 1. Utiliser -X POST (pas PUT)
# 2. Content-Type DOIT être application/x-ndjson
# 3. Utiliser --data-binary (pas -d ni --data) pour préserver les \n
# 4. Chaque document = 2 lignes : {action}\n{document}\n
echo "Chargement du catalogue via Bulk API..."
curl -s -X POST "$BASE_URL/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @"$BULK_FILE" | jq '{total: (.items | length), errors: .errors, took: .took}' 2>/dev/null

# Rafraîchir après le bulk
curl -s -X POST "$BASE_URL/$INDEX/_refresh" > /dev/null

# =============================================================================
# EXERCICE 5 — Vérifications
# =============================================================================

echo_step "EXERCICE 5 — Vérifications finales"

echo "Statistiques de l'index :"
curl -s "$BASE_URL/_cat/indices/$INDEX?v"

echo ""
echo "Nombre total de documents :"
curl -s "$BASE_URL/$INDEX/_count"

echo ""
echo "Échantillon de documents (5 premiers) :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match_all": {} },
    "size": 5,
    "_source": ["name", "category", "price", "in_stock", "brand"]
  }'

echo ""
echo "Distribution des catégories :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "par_categorie": {
        "terms": {
          "field": "category",
          "size": 20
        }
      }
    }
  }' | jq '.aggregations.par_categorie.buckets[] | {key, doc_count}' 2>/dev/null

echo ""
echo_ok "TP2 Solution complète exécutée !"
echo ""
echo "=== RÉSUMÉ DES POINTS CLÉS ==="
echo ""
echo "1. PUT /index/_doc/{id}  => Crée ou REMPLACE entièrement le document"
echo "2. POST /index/_update/{id} avec {\"doc\":{}} => Mise à jour PARTIELLE (merge)"
echo "3. GET /index/_doc/{id}  => Récupère un document par son ID"
echo "4. DELETE /index/_doc/{id} => Supprime un document"
echo "5. POST /_bulk avec --data-binary => Opérations en masse (NDJSON)"
echo "6. POST /index/_refresh => Rend les modifications visibles immédiatement"
echo ""
echo "=== MAPPING : RÈGLES D'OR ==="
echo ""
echo "- 'text'    : champs de recherche full-text (name, description)"
echo "- 'keyword' : champs de filtre/agrégation (category, brand, color)"
echo "- 'float'   : prix, notes"
echo "- 'boolean' : in_stock"
echo "- 'date'    : created_at, updated_at (format ISO 8601)"
echo "- fields.keyword : double mapping text+keyword sur un même champ"
