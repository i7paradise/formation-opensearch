# TP3 — Requêtes & Agrégations

## Objectif

Maîtriser le Query DSL d'OpenSearch et les agrégations pour implémenter des fonctionnalités de recherche et d'analyse sur notre catalogue e-commerce.

## Prérequis

- TP2 terminé et validé
- Index `products` avec au moins 1000 documents
- Cluster OpenSearch en cours d'exécution

## Durée estimée

45 minutes

## Contexte fil rouge

Notre catalogue produits est chargé. Maintenant, les utilisateurs ont besoin de pouvoir **trouver des produits** et les responsables e-commerce ont besoin d'**analyser le catalogue**. Dans ce TP, vous allez implémenter :

- La barre de recherche principale (full-text sur les noms et descriptions)
- Les filtres produits (catégorie, prix, disponibilité)
- La page "résultats de recherche" avec filtres combinés
- Les statistiques du catalogue pour le back-office (prix moyen par catégorie, distribution des prix)

---

## Introduction au Query DSL

OpenSearch utilise un langage de requêtes JSON appelé **Query DSL** (Domain Specific Language). Il existe deux contextes d'exécution :

### Contexte de requête (Query context)
La question posée est : **"Ce document correspond-il à la requête ?"** et **"Dans quelle mesure ?"**
Les documents sont retournés avec un score de pertinence (`_score`).
Exemple : `match`, `multi_match`, `query_string`

### Contexte de filtre (Filter context)
La question posée est : **"Ce document correspond-il à ce critère ? (Oui/Non)"**
Aucun score calculé → plus rapide, résultats mis en cache.
Exemple : `term`, `terms`, `range`, `exists`

> **Règle d'or** : Utilisez le contexte de requête pour la pertinence (recherche full-text), et le contexte de filtre pour les critères binaires (filtres de facettes).

---

## Exercice 1 — Recherche full-text (match query)

La `match` query est la requête de recherche full-text de base. Elle analyse le texte avant la recherche.

### 1.1 Rechercher dans les noms de produits

Dans `exercices.sh`, complétez le TODO pour chercher les produits contenant "ordinateur" dans le champ `name`.

Structure de la requête :
```json
GET /products/_search
{
  "query": {
    "match": {
      "champ": "termes de recherche"
    }
  }
}
```

Observez :
- Le champ `hits.total.value` : combien de résultats ?
- Le champ `_score` de chaque résultat : comment est-il calculé ?
- L'ordre des résultats : par quel critère sont-ils triés ?

### 1.2 Recherche dans plusieurs champs (multi_match)

Cherchez "bluetooth" dans `name` et `description` simultanément :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
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
    "_source": ["name", "description", "price"]
  }' | python3 -m json.tool
```

> **Boosting** : `name^2` signifie que le champ `name` compte double dans le calcul du score. Un match dans le nom d'un produit est plus pertinent qu'un match dans la description.

### 1.3 Opérateur AND vs OR

Par défaut, `match` utilise l'opérateur OR (un terme suffit). Essayez avec AND :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": {
        "name": {
          "query": "casque bluetooth",
          "operator": "and"
        }
      }
    }
  }' | python3 -m json.tool
```

Comparez le nombre de résultats avec l'opérateur OR (défaut).

---

## Exercice 2 — Filtres (filter context)

Les filtres sont utilisés pour les critères de sélection binaires. Ils sont plus rapides que les requêtes car les résultats sont mis en cache.

### 2.1 Filtrer les produits en stock dans une fourchette de prix

Complétez le TODO dans `exercices.sh` pour trouver les produits :
- En stock (`in_stock: true`)
- Avec un prix entre 100€ et 500€

Structure avec `bool` + `filter` + `range` :
```json
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "in_stock": true } },
        { "range": { "price": { "gte": 100, "lte": 500 } } }
      ]
    }
  }
}
```

### 2.2 Filtrer par catégorie spécifique

Ajoutez un filtre sur la catégorie "Électronique" :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
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
    "size": 5,
    "_source": ["name", "category", "price", "in_stock"]
  }' | python3 -m json.tool
```

### 2.3 Filtrer avec `terms` (plusieurs valeurs)

Cherchez les produits dans plusieurs catégories à la fois :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "filter": [
          {
            "terms": {
              "category": ["Électronique", "Livres"]
            }
          }
        ]
      }
    },
    "size": 5,
    "_source": ["name", "category", "price"]
  }' | python3 -m json.tool
```

---

## Exercice 3 — Bool query (requête combinée)

La `bool` query est la requête la plus polyvalente. Elle combine plusieurs clauses :

| Clause | Description |
|--------|-------------|
| `must` | Le document DOIT correspondre — contribue au score |
| `should` | Le document DEVRAIT correspondre — augmente le score si présent |
| `filter` | Le document DOIT correspondre — pas de score, mis en cache |
| `must_not` | Le document NE DOIT PAS correspondre — pas de score |

### 3.1 Bool query combinée

Complétez le TODO dans `exercices.sh` pour trouver :
- Smartphones (`must` : match "smartphone" dans le nom)
- En stock (`filter` : `in_stock: true`)
- PAS de la marque "TechBrand" (`must_not` : term sur brand)

Structure :
```json
{
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
  }
}
```

### 3.2 Ajouter un `should` pour booster certains résultats

Boostez les produits avec une note supérieure à 4.5 :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
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
          { "range": { "reviews_count": { "gte": 1000 } } }
        ],
        "minimum_should_match": 0
      }
    },
    "size": 10,
    "_source": ["name", "price", "rating", "reviews_count"],
    "sort": [
      { "_score": "desc" }
    ]
  }' | python3 -m json.tool
```

---

## Exercice 4 — Agrégations : prix moyen par catégorie

Les agrégations permettent d'analyser les données du catalogue. Elles fonctionnent sur les champs `keyword`, `numeric` et `date`.

### 4.1 Terms + Avg imbriquées

Complétez le TODO dans `exercices.sh` pour calculer le **prix moyen** de chaque catégorie.

Structure d'une agrégation imbriquée :
```json
{
  "size": 0,
  "aggs": {
    "nom_agregation_parent": {
      "terms": {
        "field": "category",
        "size": 20
      },
      "aggs": {
        "nom_agregation_enfant": {
          "avg": {
            "field": "price"
          }
        }
      }
    }
  }
}
```

> **`"size": 0`** : Indique à OpenSearch de ne pas retourner de documents (uniquement les résultats d'agrégation). Cela améliore les performances.

### 4.2 Ajouter des statistiques étendues

Remplacez `avg` par `extended_stats` pour obtenir min, max, moyenne, écart-type :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "par_categorie": {
        "terms": {
          "field": "category",
          "size": 10
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
  }' | python3 -m json.tool
```

---

## Exercice 5 — Histogramme de prix par tranches de 100€

L'agrégation `histogram` divise les valeurs numériques en intervalles réguliers (buckets).

### 5.1 Histogramme simple

Complétez le TODO dans `exercices.sh` pour créer un histogramme de prix avec des intervalles de 100€.

Structure :
```json
{
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
}
```

- `interval` : largeur de chaque tranche
- `min_doc_count` : ignorer les tranches vides (0 document)

### 5.2 Histogramme avec filtre

Appliquez l'histogramme uniquement sur les produits en stock, en Électronique :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
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
  }' | python3 -m json.tool
```

### 5.3 Range agrégation (tranches non uniformes)

Pour des tranches personnalisées (utile pour les interfaces e-commerce avec des filtres "Moins de 50€", "50€-200€", etc.) :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
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
  }' | python3 -m json.tool
```

---

## Exercice 6 — Comprendre le score avec `_explain`

L'API `_explain` vous permet de comprendre pourquoi un document a reçu un certain score de pertinence.

### 6.1 Exécuter une recherche et récupérer l'ID du premier résultat

```bash
RESULT=$(curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": { "name": "ordinateur" }
    },
    "size": 1
  }')

echo "$RESULT" | python3 -m json.tool

# Extraire l'ID du premier résultat
DOC_ID=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['hits']['hits'][0]['_id'])")
echo "ID du premier document : $DOC_ID"
```

### 6.2 Appeler `_explain` sur ce document

Complétez le TODO dans `exercices.sh` :

```bash
curl -s -X GET "http://localhost:9200/products/_explain/$DOC_ID" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": { "name": "ordinateur" }
    }
  }' | python3 -m json.tool
```

### 6.3 Analyser l'explication

La réponse de `_explain` contient une arborescence d'explication du score :
- **`max_score`** : score final du document
- **`description`** : formule appliquée (BM25 par défaut)
- **`details`** : décomposition terme par terme

Les facteurs du score BM25 :
- **tf (term frequency)** : fréquence du terme dans le document
- **idf (inverse document frequency)** : rareté du terme dans l'index
- **norm** : normalisation par la longueur du document

---

## TP Bonus — Agrégation imbriquée avancée

Trouvez le produit le plus cher et le moins cher dans chaque catégorie :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
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
          "prix_max": {
            "max": { "field": "price" }
          },
          "prix_min": {
            "min": { "field": "price" }
          },
          "prix_moyen": {
            "avg": { "field": "price" }
          },
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
  }' | python3 -m json.tool
```

---

## Vérification finale

Cochez chaque point avant de passer au TP4 :

- [ ] La `match` query sur "ordinateur" retourne des résultats avec des scores
- [ ] Les filtres `in_stock` + `range` price retournent uniquement les produits correspondants
- [ ] La `bool` query combine correctement `must`, `filter` et `must_not`
- [ ] L'agrégation `terms` + `avg` affiche le prix moyen par catégorie
- [ ] L'histogramme de prix montre la distribution avec des intervalles de 100€
- [ ] `_explain` affiche la décomposition du score BM25

---

## Récapitulatif des requêtes essentielles

| Requête | Contexte | Usage e-commerce |
|---------|----------|-----------------|
| `match` | Query | Barre de recherche principale |
| `multi_match` | Query | Recherche dans nom + description |
| `term` | Filter | Filtre catégorie exacte |
| `terms` | Filter | Filtre multi-catégories |
| `range` | Filter | Filtre de prix, de stock |
| `bool` | Mixte | Combinaison de critères |
| `terms` agg | — | Facettes de catégories |
| `avg` agg | — | Prix moyen par catégorie |
| `histogram` agg | — | Distribution des prix |
| `_explain` | — | Débogage du scoring |

---

*Passez au [TP4 — Fonctionnalités Avancées](../tp4-fonctionnalites-avancees/README.md) une fois toutes les vérifications validées.*
