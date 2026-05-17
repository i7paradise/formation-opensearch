#!/bin/bash
# =============================================================================
# TP3 — SOLUTION COMPLÈTE
# Requêtes & Agrégations OpenSearch — Recherche et analyse e-commerce
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
# EXERCICE 1 — SOLUTION : Recherche full-text (match query)
# =============================================================================

echo_step "EXERCICE 1 — SOLUTION : match query"

# POURQUOI : La match query analyse le terme "ordinateur" avec l'analyseur standard
# avant de l'chercher dans l'index. L'analyseur standard :
# 1. Tokenise le texte (découpe en mots)
# 2. Met en minuscules
# 3. Retire la ponctuation
# Le résultat est trié par _score décroissant (BM25).

echo "Solution : Recherche full-text 'ordinateur' dans le champ name"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": {
        "name": "ordinateur"
      }
    },
    "size": 5,
    "_source": ["name", "category", "price"],
    "track_total_hits": true
  }'

echo_ok "La match query retourne les documents correspondants triés par pertinence"

# =============================================================================
# EXERCICE 2 — SOLUTION : Filtres (filter context)
# =============================================================================

echo_step "EXERCICE 2 — SOLUTION : Filtres"

# POURQUOI : Les filtres dans la clause "filter" de bool query ne calculent PAS de score.
# Ils répondent à une question binaire : le document correspond-il au critère ?
# Avantages :
# - Plus rapides (pas de calcul de score)
# - Résultats mis en cache automatiquement par OpenSearch
# - Idéaux pour les facettes e-commerce (catégorie, prix, disponibilité)

echo "Solution : Produits en stock, prix entre 100€ et 500€"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "filter": [
          { "term": { "in_stock": true } },
          { "range": { "price": { "gte": 100, "lte": 500 } } }
        ]
      }
    },
    "size": 5,
    "_source": ["name", "price", "in_stock", "category"],
    "sort": [
      { "price": { "order": "asc" } }
    ]
  }'

# REMARQUE : Les filtres utilisent "term" (pas "match") pour les champs keyword.
# "term" effectue une comparaison exacte — parfait pour les booléens, keywords, IDs.
# Si on utilisait "match" sur "in_stock", cela fonctionnerait mais serait moins efficace.

echo_ok "Les filtres ne calculent pas de score : _score est 0.0 pour tous les résultats"

# =============================================================================
# EXERCICE 3 — SOLUTION : Bool query combinée
# =============================================================================

echo_step "EXERCICE 3 — SOLUTION : Bool query"

# POURQUOI chaque clause :
# - "must" { match: name "smartphone" } : on veut des smartphones → contribue au score
# - "filter" { term: in_stock true }    : filtre strict, pas de score (plus rapide)
# - "must_not" { term: brand "TechBrand" } : exclure cette marque complètement
#
# On utilise "must" pour "smartphone" (et pas "filter") parce qu'on veut que la
# pertinence du terme influence le classement. Un document qui parle beaucoup de
# "smartphone" sera mieux classé qu'un document qui le mentionne une fois.

echo "Solution : Smartphones en stock, sans la marque TechBrand"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "name": "smartphone" } }
        ],
        "filter": [
          { "term": { "in_stock": true } }
        ],
        "must_not": [
          { "term": { "brand": "TechBrand" } }
        ]
      }
    },
    "size": 5,
    "_source": ["name", "brand", "price", "in_stock", "rating"]
  }'

echo_ok "Bool query : must (score) + filter (rapide) + must_not (exclusion)"

# =============================================================================
# EXERCICE 4 — SOLUTION : Agrégation prix moyen par catégorie
# =============================================================================

echo_step "EXERCICE 4 — SOLUTION : Agrégation prix moyen par catégorie"

# POURQUOI "size": 0 : On ne veut pas de documents dans la réponse, uniquement les
# résultats des agrégations. Cela évite de transférer inutilement des données.
#
# POURQUOI imbriquer avg dans terms : Les agrégations imbriquées (sub-aggregations)
# calculent une métrique pour CHAQUE bucket de l'agrégation parente.
# Ici : pour chaque catégorie (bucket terms), calculer la moyenne de price.
#
# Équivalent SQL approximatif :
# SELECT category, AVG(price) FROM products GROUP BY category LIMIT 20

echo "Solution : Prix moyen par catégorie (terms + avg)"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "par_categorie": {
        "terms": {
          "field": "category",
          "size": 20,
          "order": { "prix_moyen": "desc" }
        },
        "aggs": {
          "prix_moyen": {
            "avg": {
              "field": "price"
            }
          }
        }
      }
    }
  }'

echo_ok "Agrégation terms + avg : prix moyen calculé pour chaque catégorie"

# =============================================================================
# EXERCICE 5 — SOLUTION : Histogramme de prix
# =============================================================================

echo_step "EXERCICE 5 — SOLUTION : Histogramme de prix"

# POURQUOI histogram : Cette agrégation crée automatiquement des buckets (intervalles)
# réguliers sur un champ numérique. Chaque bucket représente une tranche de prix.
#
# "interval": 100 → tranches de 100€ en 100€ : [0-100[, [100-200[, [200-300[...
# "min_doc_count": 1 → on n'affiche pas les tranches vides (0 produit)
#
# C'est l'équivalent d'un histogramme dans un graphique de visualisation.
# Dans OpenSearch Dashboards, ce type d'agrégation alimente directement les bar charts.

echo "Solution : Histogramme de prix (tranches de 100€)"
curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
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

echo_ok "Histogramme : chaque bucket = une tranche de 100€ avec son nombre de produits"

# =============================================================================
# EXERCICE 6 — SOLUTION : _explain
# =============================================================================

echo_step "EXERCICE 6 — SOLUTION : Analyse du score avec _explain"

# Récupérer l'ID du premier résultat pour "ordinateur"
RESULT=$(curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"name":"ordinateur"}},"size":1}')

TOTAL=$(echo "$RESULT" | jq -r '.hits.total.value' 2>/dev/null || echo "0")

if [ "$TOTAL" -gt 0 ]; then
  DOC_ID=$(echo "$RESULT" | jq -r '.hits.hits[0]._id' 2>/dev/null)
  DOC_SCORE=$(echo "$RESULT" | jq -r '.hits.hits[0]._score' 2>/dev/null)

  echo "Document analysé — ID: $DOC_ID, score: $DOC_SCORE"
  echo ""

  # POURQUOI _explain est utile :
  # En production, les utilisateurs se plaignent parfois que "ce produit devrait
  # apparaître en premier !". _explain permet de déboguer exactement pourquoi
  # un document a un certain score en décomposant la formule BM25 terme par terme.
  #
  # BM25 = f(tf, idf, dl, avgdl)
  # - tf  : plus le terme est fréquent dans le doc, plus le score est élevé
  # - idf : plus le terme est rare dans l'index, plus le score est élevé
  # - dl  : les documents courts sont favorisés (moins de bruit)

  echo "Solution : _explain sur le premier résultat"
  curl -s -X GET "$BASE_URL/$INDEX/_explain/$DOC_ID" \
    -H 'Content-Type: application/json' \
    -d '{
      "query": {
        "match": { "name": "ordinateur" }
      }
    }'

  echo ""
  echo "Lecture du score BM25 :"
  echo "  - 'weight(name:ordinateur in X)' : poids du terme 'ordinateur' dans ce document"
  echo "  - 'idf(docFreq=N, docCount=M)'   : rareté du terme (N docs / M total)"
  echo "  - 'tfNorm'                        : fréquence normalisée par longueur du champ"
  echo "  Score final = idf * tfNorm"
else
  echo "Aucun résultat pour 'ordinateur'. Les données ne sont peut-être pas chargées."
fi

echo ""
echo "Analyse de l'analyseur standard sur 'Ordinateur Portable Ultra-Rapide' :"
curl -s -X POST "$BASE_URL/$INDEX/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
    "field": "name",
    "text": "Ordinateur Portable Ultra-Rapide"
  }'

# =============================================================================
# BONUS — Agrégation imbriquée avancée
# =============================================================================

echo_step "BONUS — Top 5 catégories avec produit le plus cher et le moins cher"

# POURQUOI top_hits : C'est une agrégation spéciale qui retourne les documents
# eux-mêmes (et pas juste des métriques) pour chaque bucket.
# Ici : pour chaque catégorie, donner le document le plus cher et le moins cher.

curl -s -X GET "$BASE_URL/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "top_5_categories": {
        "terms": {
          "field": "category",
          "size": 5,
          "order": { "_count": "desc" }
        },
        "aggs": {
          "prix_moyen": { "avg": { "field": "price" } },
          "prix_max": { "max": { "field": "price" } },
          "prix_min": { "min": { "field": "price" } },
          "produit_le_plus_cher": {
            "top_hits": {
              "size": 1,
              "sort": [{ "price": { "order": "desc" } }],
              "_source": ["name", "price", "brand"]
            }
          },
          "produit_le_moins_cher": {
            "top_hits": {
              "size": 1,
              "sort": [{ "price": { "order": "asc" } }],
              "_source": ["name", "price", "brand"]
            }
          }
        }
      }
    }
  }'

echo ""
echo_ok "TP3 Solution complète exécutée !"
echo ""
echo "=== RÉCAPITULATIF DES PATTERNS CLÉS ==="
echo ""
echo "RECHERCHE FULL-TEXT :"
echo "  match           → un champ, analyse le texte"
echo "  multi_match     → plusieurs champs, boosting avec ^N"
echo ""
echo "FILTRES (pas de score, mis en cache) :"
echo "  term            → valeur exacte unique (keyword, boolean)"
echo "  terms           → plusieurs valeurs exactes"
echo "  range           → plage numérique ou de dates (gte/lte/gt/lt)"
echo ""
echo "BOOL QUERY (combinaison) :"
echo "  must            → obligatoire + contribue au score"
echo "  filter          → obligatoire, sans score (plus rapide)"
echo "  must_not        → exclusion, sans score"
echo "  should          → optionnel, augmente le score si présent"
echo ""
echo "AGRÉGATIONS :"
echo "  terms           → GROUP BY (facettes)"
echo "  avg/min/max     → métriques numériques"
echo "  extended_stats  → toutes les statistiques en une fois"
echo "  histogram       → distribution par intervalles réguliers"
echo "  range           → distribution par intervalles personnalisés"
echo "  top_hits        → documents par bucket"
