#!/bin/bash
# TP4 — Solution complète — Fonctionnalités Avancées
# Chaque commande est commentée pour expliquer POURQUOI elle fonctionne

BASE_URL="http://localhost:9200"

echo "================================================"
echo " TP4 — Solution : Fonctionnalités Avancées"
echo "================================================"

# ============================================
# EXERCICE 1 : Ingest Pipeline
# ============================================
echo ""
echo "=== Exercice 1 : Création du pipeline ==="

# Le pipeline normalise les données à l'indexation :
# - lowercase : garantit que "ELECTRONIQUE" et "Electronique" sont traités de façon identique
# - trim : supprime les espaces en début/fin qui fausseraient les recherches sur champs keyword
# - set : ajoute un timestamp d'indexation pour l'audit
curl -s -X PUT "$BASE_URL/_ingest/pipeline/pipeline-produits" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Pipeline normalisation produits e-commerce",
  "processors": [
    {
      "lowercase": {
        "field": "category",
        "ignore_missing": true
      }
    },
    {
      "trim": {
        "field": "description",
        "ignore_missing": true
      }
    },
    {
      "set": {
        "field": "indexed_at",
        "value": "{{_ingest.timestamp}}"
      }
    }
  ]
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Test du pipeline avec _simulate ---"
# _simulate permet de tester sans indexer réellement — essentiel avant de déployer en prod !
curl -s -X POST "$BASE_URL/_ingest/pipeline/pipeline-produits/_simulate" \
  -H 'Content-Type: application/json' \
  -d '{
  "docs": [
    {
      "_source": {
        "name": "MacBook Pro 16 pouces",
        "category": "ELECTRONIQUE",
        "description": "   Ordinateur portable Apple avec puce M3 Pro.   ",
        "price": 2499.99
      }
    }
  ]
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Indexation d un produit avec le pipeline ---"
# Le paramètre ?pipeline= déclenche le pipeline avant l'indexation
curl -s -X PUT "$BASE_URL/products/_doc/test-pipeline-001?pipeline=pipeline-produits" \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "Vélo électrique VTT Pro",
  "category": "SPORTS",
  "description": "   VTT électrique 27.5 pouces, moteur 250W, autonomie 80km.   ",
  "price": 1299.00,
  "in_stock": true
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Vérification : category doit être en minuscules et indexed_at présent ---"
curl -s "$BASE_URL/products/_doc/test-pipeline-001?pretty"


# ============================================
# EXERCICE 2 : Analyseur Français
# ============================================
echo ""
echo "=== Exercice 2 : Création de l index avec analyseur français ==="

# Pourquoi un analyseur personnalisé ?
# - lowercase : "Vélo" → "vélo"
# - asciifolding : "vélo" → "velo" (recherche insensible aux accents)
# - french_stop : supprime "de", "le", "la", etc. (stop words français)
# - french_stemmer : "vélos" → "velo", "courir" → "cour" (racines communes)
# Résultat : chercher "velo" trouve "Vélos", "Vélo", "vélos électriques"

curl -s -X DELETE "$BASE_URL/products-v2" > /dev/null 2>&1  # Nettoyer si existe

curl -s -X PUT "$BASE_URL/products-v2" \
  -H 'Content-Type: application/json' \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "analysis": {
      "filter": {
        "french_stemmer": {
          "type": "stemmer",
          "language": "french"
        },
        "french_stop": {
          "type": "stop",
          "stopwords": "_french_"
        }
      },
      "analyzer": {
        "french_custom": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "asciifolding",
            "french_stop",
            "french_stemmer"
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": {
        "type": "text",
        "analyzer": "french_custom",
        "fields": {
          "keyword": { "type": "keyword" }
        }
      },
      "description": {
        "type": "text",
        "analyzer": "french_custom"
      },
      "category": { "type": "keyword" },
      "sub_category": { "type": "keyword" },
      "brand": { "type": "keyword" },
      "price": { "type": "float" },
      "original_price": { "type": "float" },
      "in_stock": { "type": "boolean" },
      "stock_quantity": { "type": "integer" },
      "rating": { "type": "float" },
      "reviews_count": { "type": "integer" },
      "tags": { "type": "keyword" },
      "created_at": { "type": "date" },
      "updated_at": { "type": "date" },
      "seller": { "type": "keyword" },
      "weight_kg": { "type": "float" },
      "color": { "type": "keyword" }
    }
  }
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Test de l analyseur : 'Vélos électriques d entrée de gamme' ---"
# On voit ici la tokenisation complète, avec suppression des accents et des stop words
curl -s -X POST "$BASE_URL/products-v2/_analyze" \
  -H 'Content-Type: application/json' \
  -d '{
  "analyzer": "french_custom",
  "text": "Vélos électriques d'\''entrée de gamme"
}' | python3 -m json.tool 2>/dev/null


# ============================================
# EXERCICE 3 : Réindexation
# ============================================
echo ""
echo "=== Exercice 3 : Réindexation products → products-v2 ==="

# _reindex copie les documents d'un index vers un autre
# Sans modifier les données sources — non-destructif
curl -s -X POST "$BASE_URL/_reindex?wait_for_completion=true" \
  -H 'Content-Type: application/json' \
  -d '{
  "source": {
    "index": "products"
  },
  "dest": {
    "index": "products-v2"
  }
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Vérification des counts ---"
echo -n "products count: "
curl -s "$BASE_URL/products/_count" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])" 2>/dev/null
echo -n "products-v2 count: "
curl -s "$BASE_URL/products-v2/_count" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])" 2>/dev/null

echo ""
echo "--- Comparaison : chercher 'velo' dans products vs products-v2 ---"
echo -n "Résultats dans products (sans analyseur français): "
curl -s "$BASE_URL/products/_search?q=name:velo&size=0" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['hits']['total']['value'])" 2>/dev/null
echo -n "Résultats dans products-v2 (avec analyseur français): "
curl -s "$BASE_URL/products-v2/_search?q=name:velo&size=0" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['hits']['total']['value'])" 2>/dev/null


# ============================================
# EXERCICE 4 : Completion Suggester
# ============================================
echo ""
echo "=== Exercice 4 : Completion Suggester ==="

# Pour le completion suggester, on a besoin d'un champ de type "completion"
# Il faut créer un index avec ce champ dans le mapping
echo "--- Création de products-v3 avec champ name_suggest ---"
curl -s -X DELETE "$BASE_URL/products-v3" > /dev/null 2>&1

curl -s -X PUT "$BASE_URL/products-v3" \
  -H 'Content-Type: application/json' \
  -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "analysis": {
      "filter": {
        "french_stemmer": { "type": "stemmer", "language": "french" },
        "french_stop": { "type": "stop", "stopwords": "_french_" }
      },
      "analyzer": {
        "french_custom": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "french_stop", "french_stemmer"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": { "type": "text", "analyzer": "french_custom" },
      "name_suggest": { "type": "completion" },
      "description": { "type": "text", "analyzer": "french_custom" },
      "category": { "type": "keyword" },
      "price": { "type": "float" },
      "in_stock": { "type": "boolean" },
      "rating": { "type": "float" }
    }
  }
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Réindexation avec script pour copier name vers name_suggest ---"
curl -s -X POST "$BASE_URL/_reindex?wait_for_completion=true" \
  -H 'Content-Type: application/json' \
  -d '{
  "source": { "index": "products" },
  "dest": { "index": "products-v3" },
  "script": {
    "source": "ctx._source.name_suggest = ctx._source.name"
  }
}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Réindexé: {d.get(\"created\",0)} docs')" 2>/dev/null

echo ""
echo "--- Test autocomplétion pour le préfixe 'ordi' ---"
curl -s -X POST "$BASE_URL/products-v3/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "_source": false,
  "suggest": {
    "produit-suggest": {
      "prefix": "ordi",
      "completion": {
        "field": "name_suggest",
        "size": 5,
        "fuzzy": { "fuzziness": 1 }
      }
    }
  }
}' | python3 -m json.tool 2>/dev/null


# ============================================
# EXERCICE 5 : Highlighting
# ============================================
echo ""
echo "=== Exercice 5 : Highlighting ==="

# Le highlighting extrait des fragments de texte et entoure les termes matchés
# pre_tags/post_tags définissent les balises de surligange
# fragment_size : longueur max de l'extrait en caractères
# number_of_fragments : nombre max d'extraits retournés par champ
curl -s -X POST "$BASE_URL/products-v2/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "query": {
    "multi_match": {
      "query": "ordinateur portable",
      "fields": ["name", "description"]
    }
  },
  "highlight": {
    "pre_tags": ["<mark>"],
    "post_tags": ["</mark>"],
    "fields": {
      "name": {},
      "description": {
        "fragment_size": 150,
        "number_of_fragments": 2
      }
    }
  },
  "size": 3
}' | python3 -m json.tool 2>/dev/null


# ============================================
# EXERCICE 6 : Recherche Géographique
# ============================================
echo ""
echo "=== Exercice 6 : Recherche géographique ==="

# geo_distance filtre selon un cercle autour d'un point GPS
# _geo_distance dans sort trie par distance et retourne la distance calculée
# L'index stores doit avoir le champ 'location' de type geo_point
curl -s -X POST "$BASE_URL/stores/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "query": {
    "geo_distance": {
      "distance": "5km",
      "location": {
        "lat": 48.8566,
        "lon": 2.3522
      }
    }
  },
  "sort": [
    {
      "_geo_distance": {
        "location": {
          "lat": 48.8566,
          "lon": 2.3522
        },
        "order": "asc",
        "unit": "km",
        "distance_type": "arc"
      }
    }
  ],
  "_source": ["name", "city", "address", "type"],
  "size": 10
}' | python3 -m json.tool 2>/dev/null


# ============================================
# BONUS A : Term Suggester ("Voulez-vous dire ?")
# ============================================
echo ""
echo "=== Bonus A : Term Suggester ==="

# suggest_mode "missing" : ne suggère que si le terme n'existe pas dans l'index
# max_edits: 2 : distance d'édition maximale (2 = "ordi" → "orden", 2 caractères différents)
# min_word_length: 4 : ne tente pas de corriger les mots très courts
curl -s -X POST "$BASE_URL/products-v2/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "suggest": {
    "correction-ortho": {
      "text": "ordenateur portatif",
      "term": {
        "field": "name",
        "suggest_mode": "missing",
        "max_edits": 2,
        "min_word_length": 4,
        "min_doc_freq": 1
      }
    }
  }
}' | python3 -m json.tool 2>/dev/null


# ============================================
# BONUS B : Geo Bounding Box
# ============================================
echo ""
echo "=== Bonus B : Geo Bounding Box — Île-de-France ==="

# geo_bounding_box définit un rectangle par les coins nord-ouest et sud-est
# Plus rapide que geo_distance car pas de calcul de distance circulaire
curl -s -X POST "$BASE_URL/stores/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "query": {
    "geo_bounding_box": {
      "location": {
        "top_left": { "lat": 49.0, "lon": 1.8 },
        "bottom_right": { "lat": 48.1, "lon": 3.0 }
      }
    }
  },
  "_source": ["name", "city", "location"],
  "size": 20
}' | python3 -m json.tool 2>/dev/null

echo ""
echo "================================================"
echo " TP4 Solution terminée !"
echo "================================================"
