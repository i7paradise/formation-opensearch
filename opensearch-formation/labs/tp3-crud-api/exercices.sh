#!/bin/bash
# =============================================================================
# TP2 — CRUD & API OpenSearch
# Moteur de recherche e-commerce — Chargement du catalogue produits
# =============================================================================
# Usage : bash exercices.sh
# Prérequis : cluster OpenSearch en cours d'exécution sur localhost:9200
# =============================================================================

BASE_URL="http://localhost:9200"
INDEX="products"

# Couleurs pour l'affichage
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_step() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

echo_ok() {
  echo -e "${GREEN}[OK]${NC} $1"
}

echo_todo() {
  echo -e "${YELLOW}[TODO]${NC} $1"
}

# =============================================================================
# EXERCICE 1 — Créer l'index products avec un mapping explicite
# =============================================================================

echo_step "EXERCICE 1 — Création de l'index products"

# Supprimer l'index s'il existe déjà (pour repartir proprement)
echo "Suppression de l'index existant (si présent)..."
curl -s -X DELETE "$BASE_URL/$INDEX" > /dev/null
sleep 1

# Créer l'index avec le mapping complet
# Le mapping définit le type de chaque champ et comment il est indexé
echo "Création de l'index $INDEX avec mapping explicite..."

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
  }' | python3 -m json.tool

echo ""
echo "Vérification du mapping créé :"
curl -s "$BASE_URL/$INDEX/_mapping" | python3 -m json.tool | head -30
echo "..."

# =============================================================================
# EXERCICE 2 — Indexer manuellement 5 produits avec PUT /_doc/{id}
# =============================================================================

echo_step "EXERCICE 2 — Indexation manuelle de produits"

# TODO: Indexer un produit Smartphone avec PUT
# Utilisez : PUT /products/_doc/1
# Corps du document : voir README.md Exercice 2.1 (Produit 1)
#
# Exemple de structure de la requête curl :
# curl -s -X PUT "$BASE_URL/$INDEX/_doc/1" \
#   -H 'Content-Type: application/json' \
#   -d '{ ... votre document JSON ici ... }' | python3 -m json.tool
#
# COMPLÉTEZ ICI :
echo_todo "Indexer le smartphone (produit ID 1) — complétez ci-dessous"
# curl -s -X PUT "$BASE_URL/$INDEX/_doc/1" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     ...
#   }' | python3 -m json.tool

echo ""

# TODO: Indexer un ordinateur portable (produit ID 2)
echo_todo "Indexer l'ordinateur portable (produit ID 2)"
# curl -s -X PUT "$BASE_URL/$INDEX/_doc/2" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     ...
#   }' | python3 -m json.tool

echo ""

# TODO: Indexer un casque audio (produit ID 3)
echo_todo "Indexer le casque audio (produit ID 3)"
# curl -s -X PUT "$BASE_URL/$INDEX/_doc/3" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     ...
#   }' | python3 -m json.tool

echo ""

# TODO: Indexer un livre (produit ID 4)
echo_todo "Indexer le livre (produit ID 4)"
# curl -s -X PUT "$BASE_URL/$INDEX/_doc/4" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     ...
#   }' | python3 -m json.tool

echo ""

# TODO: Indexer une montre connectée (produit ID 5) — en rupture de stock
echo_todo "Indexer la montre connectée (produit ID 5, in_stock: false)"
# curl -s -X PUT "$BASE_URL/$INDEX/_doc/5" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     ...
#   }' | python3 -m json.tool

# Forcer le rafraîchissement de l'index pour rendre les documents visibles immédiatement
echo ""
echo "Rafraîchissement de l'index..."
curl -s -X POST "$BASE_URL/$INDEX/_refresh" | python3 -m json.tool

# =============================================================================
# EXERCICE 3 — Lire, mettre à jour, supprimer
# =============================================================================

echo_step "EXERCICE 3 — CRUD : Lire, Mettre à jour, Supprimer"

# TODO: Récupérer le produit par son ID
# Utilisez : GET /products/_doc/{id}
echo_todo "Récupérer le smartphone par son ID (1)"
# curl -s "$BASE_URL/$INDEX/_doc/1" | python3 -m json.tool

echo ""

# Vérifier l'existence d'un document sans récupérer le corps (HEAD)
echo "Vérification de l'existence du document ID 1 (HEAD request) :"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "$BASE_URL/$INDEX/_doc/1"

echo ""

# TODO: Mettre à jour le prix du produit (mise à jour partielle)
# Utilisez : POST /products/_update/1 avec {"doc": {"price": 799.99}}
# La mise à jour partielle ne modifie que les champs spécifiés
echo_todo "Mettre à jour le prix du smartphone à 799.99€"
# curl -s -X POST "$BASE_URL/$INDEX/_update/1" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     ...
#   }' | python3 -m json.tool

echo ""

# Mise à jour avec un script Painless (calcul de remise 10%)
echo "Mise à jour scriptée : remise de 10% sur le casque audio (ID 3) :"
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
  }' | python3 -m json.tool

echo ""
echo "Vérification du nouveau prix du casque (ID 3) :"
curl -s "$BASE_URL/$INDEX/_doc/3" | python3 -m json.tool | grep -E '"price"|"updated_at"'

echo ""

# TODO: Supprimer le produit ID 5 (montre connectée - en rupture de stock)
# Utilisez : DELETE /products/_doc/{id}
echo_todo "Supprimer la montre connectée (produit ID 5 — en rupture de stock)"
# curl -s -X DELETE "$BASE_URL/$INDEX/_doc/5" | python3 -m json.tool

echo ""

# Vérifier que le document supprimé n'existe plus
echo "Vérification que le document ID 5 n'existe plus :"
curl -s "$BASE_URL/$INDEX/_doc/5" | python3 -m json.tool

# =============================================================================
# EXERCICE 4 — Charger le catalogue via Bulk API
# =============================================================================

echo_step "EXERCICE 4 — Bulk API : chargement du catalogue complet"

# Chemin vers le fichier NDJSON des produits
# Le fichier se trouve dans data/ à la racine du projet
BULK_FILE="../../data/products-bulk.ndjson"

if [ ! -f "$BULK_FILE" ]; then
  echo -e "${RED}[ERREUR]${NC} Fichier $BULK_FILE introuvable !"
  echo "Vérifiez que le fichier products-bulk.ndjson est bien dans le dossier data/"
  echo "Chemin attendu : $(realpath "$BULK_FILE" 2>/dev/null || echo "$BULK_FILE")"
else
  echo "Chargement du fichier $BULK_FILE via Bulk API..."
  echo "Taille du fichier : $(wc -l < "$BULK_FILE") lignes"
  echo ""

  # La requête Bulk API
  # --data-binary est INDISPENSABLE pour préserver les retours à la ligne
  # Content-Type doit être application/x-ndjson (pas application/json)
  RESPONSE=$(curl -s -X POST "$BASE_URL/_bulk" \
    -H 'Content-Type: application/x-ndjson' \
    --data-binary @"$BULK_FILE")

  # Vérification des erreurs
  ERRORS=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['errors'])")
  echo "Errors dans la réponse Bulk : $ERRORS"

  if [ "$ERRORS" = "True" ]; then
    echo -e "${RED}Des erreurs ont été détectées. Affichage des 3 premières :${NC}"
    echo "$RESPONSE" | python3 -c "
import json, sys
resp = json.load(sys.stdin)
errors = [item for item in resp['items'] if list(item.values())[0].get('status', 200) >= 400]
print(f'Total erreurs: {len(errors)}')
for e in errors[:3]:
    print(json.dumps(e, indent=2, ensure_ascii=False))
"
  else
    echo_ok "Bulk API terminé sans erreur !"
  fi
fi

# Forcer le rafraîchissement
echo ""
echo "Rafraîchissement de l'index après le chargement bulk..."
curl -s -X POST "$BASE_URL/$INDEX/_refresh" | python3 -m json.tool

# =============================================================================
# EXERCICE 5 — Vérifier le chargement
# =============================================================================

echo_step "EXERCICE 5 — Vérification du chargement"

# Vérifier le nombre de documents
echo "Statistiques de l'index :"
curl -s "$BASE_URL/_cat/indices/$INDEX?v"

echo ""
echo "Nombre exact de documents :"
curl -s "$BASE_URL/$INDEX/_count" | python3 -m json.tool

echo ""
echo "Recherche de vérification (5 premiers documents) :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match_all": {} },
    "size": 5,
    "_source": ["name", "category", "price", "in_stock"]
  }' | python3 -m json.tool

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
  }' | python3 -m json.tool

echo ""
echo_ok "TP2 terminé ! Vérifiez que docs.count > 1000 avant de passer au TP3."
