#!/bin/bash
# =============================================================================
# TP3 — Requêtes & Agrégations OpenSearch
# Moteur de recherche e-commerce — Implémentation de la recherche et analyse
# =============================================================================
# Usage : bash exercices.sh
# Prérequis : TP2 terminé, index products avec 1000+ documents
# =============================================================================

BASE_URL="http://localhost:9200"
INDEX="products"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_step() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

echo_todo() {
  echo -e "${YELLOW}[TODO]${NC} $1"
}

# Vérification préalable
echo "Vérification de l'index products..."
COUNT=$(curl -s "$BASE_URL/$INDEX/_count" | jq -r '.count // 0' 2>/dev/null || echo "0")
echo "Nombre de documents dans $INDEX : $COUNT"
if [ "$COUNT" -lt 100 ]; then
  echo "ATTENTION : Moins de 100 documents trouvés. Avez-vous bien terminé le TP2 ?"
  echo "Relancez labs/tp2-crud-api/solution/solution.sh si nécessaire."
fi

# =============================================================================
# EXERCICE 1 — Recherche full-text avec match query
# =============================================================================

echo_step "EXERCICE 1 — Recherche full-text (match query)"

# La match query est la requête de recherche full-text de base.
# Elle analyse le texte de recherche avec le même analyseur que le champ indexé.
# Les résultats sont triés par score de pertinence (_score) décroissant.

# TODO: Chercher les produits contenant "ordinateur" dans le nom
# La match query analyse "ordinateur" avant de le chercher dans l'index "name"
# Conseil : affichez aussi le _score et le nombre total de résultats (hits.total.value)
echo_todo "Chercher les produits contenant 'ordinateur' dans le champ name"
# curl -s -X GET "$BASE_URL/$INDEX/_search" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     "query": {
#       ...
#     },
#     "size": 5,
#     "_source": ["name", "category", "price"]
#   }'

echo ""

# Recherche multi-champs avec boosting (déjà fourni — observez le fonctionnement)
echo "Recherche multi_match 'bluetooth' dans name (boost x2) et description :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "multi_match": {
        "query": "bluetooth",
        "fields": ["name^2", "description"],
        "type": "best_fields"
      }
    },
    "size": 5,
    "_source": ["name", "price", "_score"]
  }'

echo ""

# Comparer opérateur OR vs AND
echo "Comparaison OR vs AND pour 'casque bluetooth' :"
echo "--- Avec opérateur OR (défaut) ---"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"name":"casque bluetooth"}},"size":0}' \
  | jq -r '"Résultats OR: \(.hits.total.value)"' 2>/dev/null

echo "--- Avec opérateur AND ---"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"name":{"query":"casque bluetooth","operator":"and"}}},"size":0}' \
  | jq -r '"Résultats AND: \(.hits.total.value)"' 2>/dev/null

# =============================================================================
# EXERCICE 2 — Filtres (filter context)
# =============================================================================

echo_step "EXERCICE 2 — Filtres (filter context)"

# Les filtres ne calculent pas de score — ils répondent à une question binaire (oui/non).
# Ils sont plus rapides que les requêtes et leurs résultats sont mis en cache par OpenSearch.

# TODO: Filtrer les produits en stock avec prix entre 100 et 500€
# Utilisez une bool query avec des clauses "filter"
# Clauses nécessaires :
#   - term: { "in_stock": true }
#   - range: { "price": { "gte": 100, "lte": 500 } }
echo_todo "Filtrer les produits en stock avec prix entre 100€ et 500€"
# curl -s -X GET "$BASE_URL/$INDEX/_search" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     "query": {
#       "bool": {
#         "filter": [
#           ...
#         ]
#       }
#     },
#     "size": 5,
#     "_source": ["name", "price", "in_stock"],
#     "sort": [{"price": "asc"}]
#   }'

echo ""

# Filtre par catégorie spécifique (déjà fourni)
echo "Filtre : Produits de la catégorie 'Électronique' en stock :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "filter": [
          { "term": { "category": "Électronique" } },
          { "term": { "in_stock": true } }
        ]
      }
    },
    "size": 3,
    "_source": ["name", "category", "price"]
  }'

echo ""

# Filtre terms (plusieurs valeurs)
echo "Filtre terms : Produits dans plusieurs catégories :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "query": {
      "bool": {
        "filter": [
          { "terms": { "category": ["Électronique", "Livres"] } }
        ]
      }
    }
  }' | jq -r '"Produits Électronique + Livres : \(.hits.total.value)"' 2>/dev/null

# =============================================================================
# EXERCICE 3 — Bool query combinée
# =============================================================================

echo_step "EXERCICE 3 — Bool query : recherche combinée"

# La bool query combine plusieurs critères :
# - must   : critères OBLIGATOIRES qui contribuent au score
# - filter : critères OBLIGATOIRES sans contribution au score
# - should : critères OPTIONNELS qui améliorent le score
# - must_not : critères D'EXCLUSION (aucun score)

# TODO: Bool query : Smartphones en stock, pas de la marque "TechBrand"
# Objectif : trouver des smartphones de remplacement (pas TechBrand, en stock)
# Clauses :
#   - must    : match "smartphone" dans name
#   - filter  : in_stock = true
#   - must_not: brand = "TechBrand"
echo_todo "Bool query : Smartphones en stock, pas de la marque TechBrand"
# curl -s -X GET "$BASE_URL/$INDEX/_search" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     "query": {
#       "bool": {
#         ...
#       }
#     },
#     "size": 5,
#     "_source": ["name", "brand", "price", "in_stock"]
#   }'

echo ""

# Bool query avec should pour booster les produits bien notés
echo "Bool query avec should : ordis en stock, boostés si bien notés :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "name": "ordinateur" } }
        ],
        "filter": [
          { "term": { "in_stock": true } }
        ],
        "should": [
          { "range": { "rating": { "gte": 4.5 } } },
          { "range": { "reviews_count": { "gte": 500 } } }
        ]
      }
    },
    "size": 5,
    "_source": ["name", "price", "rating", "reviews_count"]
  }'

# =============================================================================
# EXERCICE 4 — Agrégation : prix moyen par catégorie
# =============================================================================

echo_step "EXERCICE 4 — Agrégation : prix moyen par catégorie"

# Les agrégations permettent d'analyser les données du catalogue.
# Une agrégation "terms" regroupe les documents par valeur de champ (comme un GROUP BY SQL).
# Une agrégation "avg" calcule la moyenne d'un champ numérique.
# On peut imbriquer une agrégation dans une autre (sub-aggregation).

# TODO: Agrégation - prix moyen par catégorie
# Utilisez "size": 0 pour ne retourner que les agrégations (pas de documents)
# Structure : terms sur "category" + sous-agrégation avg sur "price"
echo_todo "Calculer le prix moyen par catégorie (terms + avg imbriquées)"
# curl -s -X GET "$BASE_URL/$INDEX/_search" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     "size": 0,
#     "aggs": {
#       "par_categorie": {
#         "terms": {
#           "field": "category",
#           "size": 20
#         },
#         "aggs": {
#           ...
#         }
#       }
#     }
#   }'

echo ""

# Statistiques étendues (déjà fourni — pour comparaison)
echo "Extended stats : min, max, moyenne, écart-type par catégorie :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "par_categorie": {
        "terms": {
          "field": "category",
          "size": 5
        },
        "aggs": {
          "stats_prix": {
            "extended_stats": {
              "field": "price"
            }
          }
        }
      }
    }
  }'

# =============================================================================
# EXERCICE 5 — Histogramme de prix par tranches de 100€
# =============================================================================

echo_step "EXERCICE 5 — Histogramme de prix"

# L'agrégation "histogram" divise les valeurs numériques en intervalles réguliers.
# Chaque intervalle (bucket) contient le nombre de documents dans cette tranche de prix.
# Utile pour visualiser la distribution des prix du catalogue.

# TODO: Histogramme de prix par tranches de 100€
# Paramètres clés :
#   - field: "price"
#   - interval: 100 (taille de chaque tranche en euros)
#   - min_doc_count: 1 (exclure les tranches vides)
echo_todo "Créer un histogramme de prix avec des tranches de 100€"
# curl -s -X GET "$BASE_URL/$INDEX/_search" \
#   -H 'Content-Type: application/json' \
#   -d '{
#     "size": 0,
#     "aggs": {
#       "tranches_prix": {
#         ...
#       }
#     }
#   }'

echo ""

# Histogramme avec filtre (déjà fourni — pour voir l'effet du filtrage)
echo "Histogramme : Électronique en stock uniquement :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "query": {
      "bool": {
        "filter": [
          { "term": { "in_stock": true } },
          { "term": { "category": "Électronique" } }
        ]
      }
    },
    "aggs": {
      "tranches_prix": {
        "histogram": {
          "field": "price",
          "interval": 100,
          "min_doc_count": 1
        }
      }
    }
  }'

echo ""

# Range agrégation avec tranches personnalisées
echo "Range agrégation : tranches personnalisées (facettes e-commerce) :"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "gammes_prix": {
        "range": {
          "field": "price",
          "ranges": [
            { "key": "Moins de 50€",   "to": 50 },
            { "key": "50€ - 200€",     "from": 50,  "to": 200 },
            { "key": "200€ - 500€",    "from": 200, "to": 500 },
            { "key": "500€ - 1000€",   "from": 500, "to": 1000 },
            { "key": "Plus de 1000€",  "from": 1000 }
          ]
        }
      }
    }
  }'

# =============================================================================
# EXERCICE 6 — Comprendre le score avec _explain
# =============================================================================

echo_step "EXERCICE 6 — Analyse du score avec _explain"

# _explain révèle le calcul détaillé du score BM25 pour un document donné.
# C'est un outil indispensable pour comprendre pourquoi un résultat est bien ou mal classé.

# Étape 1 : Récupérer l'ID du premier résultat d'une recherche
echo "Recherche initiale : 'ordinateur' dans name"
RESULT=$(curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": { "name": "ordinateur" }
    },
    "size": 1
  }')

TOTAL=$(echo "$RESULT" | jq -r '.hits.total.value' 2>/dev/null || echo "0")
echo "Total de résultats pour 'ordinateur' : $TOTAL"

if [ "$TOTAL" -gt 0 ]; then
  DOC_ID=$(echo "$RESULT" | jq -r '.hits.hits[0]._id' 2>/dev/null)
  DOC_SCORE=$(echo "$RESULT" | jq -r '.hits.hits[0]._score' 2>/dev/null)
  echo "Meilleur résultat — ID: $DOC_ID | Score: $DOC_SCORE"
  echo ""

  # TODO: Expliquer le score du premier résultat
  # Utilisez GET /products/_explain/{id} avec la même query
  echo_todo "Expliquer le score du premier résultat (ID: $DOC_ID)"
  # curl -s -X GET "$BASE_URL/$INDEX/_explain/$DOC_ID" \
  #   -H 'Content-Type: application/json' \
  #   -d '{
  #     "query": {
  #       "match": { "name": "ordinateur" }
  #     }
  #   }'

  echo ""
  echo "--- Pour aller plus loin : analyse _explain complète ---"
  echo "Le résultat _explain montre l'arbre de calcul BM25 :"
  echo "  - tf  (term frequency)     : fréquence du terme dans CE document"
  echo "  - idf (inverse doc freq)   : rareté du terme dans TOUT l'index"
  echo "  - fieldNorm                : normalisation par longueur du champ"
  echo "  score = tf * idf * fieldNorm"
  echo ""
  echo "Un document court avec le terme en titre aura un score plus élevé"
  echo "qu'un document long avec le terme noyé dans une longue description."
else
  echo "Aucun résultat pour 'ordinateur'. Vérifiez que les données sont chargées."
  echo "Essayez avec un autre terme comme 'smartphone' ou 'casque'."
fi

echo ""
echo "Analyse de texte : comment OpenSearch tokenise 'Ordinateur Portable' :"
curl -s -X POST "$BASE_URL/$INDEX/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
    "field": "name",
    "text": "Ordinateur Portable Ultra-Rapide"
  }'

echo ""
echo "Fin du TP3 — Récapitulatif :"
echo "  - match query      : recherche full-text avec scoring"
echo "  - filter context   : filtres rapides sans score"
echo "  - bool query       : must + filter + must_not + should"
echo "  - terms agg + avg  : prix moyen par catégorie"
echo "  - histogram agg    : distribution des prix"
echo "  - _explain         : débogage du scoring BM25"
