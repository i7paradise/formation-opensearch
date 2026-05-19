# TP10 — Agrégations avancées

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 75 minutes                                           |
| Difficulté | Intermédiaire                                        |
| Prérequis  | TP8 terminé — index `products` avec 1000+ documents  |
| Objectif   | Maîtriser les agrégations métriques, bucket, pipeline et imbriquées |

## Objectif

Implémenter des analyses avancées sur le catalogue produits e-commerce en utilisant toutes les familles d'agrégations OpenSearch. Ces agrégations sont la base des visualisations que vous créerez dans le TP10 (Dashboards).

**Fil rouge** : "Ces résultats que vous calculez ici sont exactement ce que vous allez visualiser dans Dashboards cet après-midi."

---

## Exercice 1 — Agrégations métriques

### 1.1 Statistiques de base sur les prix

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "prix_stats": { "stats": { "field": "price" } },
    "prix_percentiles": {
      "percentiles": { "field": "price", "percents": [25, 50, 75, 95] }
    },
    "categories_distinctes": { "cardinality": { "field": "category" } }
  }
}
```

### 1.2 Statistiques étendues

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "prix_extended": {
      "extended_stats": { "field": "price" }
    }
  }
}
```

> Observez `std_deviation`, `variance`, `std_deviation_bounds` — utiles pour détecter les anomalies de prix.

---

## Exercice 2 — Agrégations bucket

### 2.1 Distribution par catégorie (`terms`)

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "par_categorie": {
      "terms": { "field": "category", "size": 20, "order": { "_count": "desc" } }
    }
  }
}
```

### 2.2 Distribution des prix par plages (`range`)

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "plages_de_prix": {
      "range": {
        "field": "price",
        "ranges": [
          { "key": "Budget (< 50€)",    "to": 50 },
          { "key": "Mid-range (50-200€)", "from": 50, "to": 200 },
          { "key": "Premium (200-500€)", "from": 200, "to": 500 },
          { "key": "Luxe (> 500€)",     "from": 500 }
        ]
      }
    }
  }
}
```

### 2.3 Histogram des prix (intervalles réguliers)

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "histogram_prix": {
      "histogram": { "field": "price", "interval": 100 }
    }
  }
}
```

---

## Exercice 3 — Agrégations imbriquées

### 3.1 Prix moyen par catégorie

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "par_categorie": {
      "terms": { "field": "category", "size": 10 },
      "aggs": {
        "prix_moyen":   { "avg": { "field": "price" } },
        "prix_max":     { "max": { "field": "price" } },
        "prix_min":     { "min": { "field": "price" } },
        "note_moyenne": { "avg": { "field": "rating" } }
      }
    }
  }
}
```

### 3.2 Top produits par catégorie (`top_hits`)

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "par_categorie": {
      "terms": { "field": "category", "size": 5 },
      "aggs": {
        "top_produits": {
          "top_hits": {
            "sort": [{ "rating": { "order": "desc" } }],
            "_source": ["name", "price", "rating"],
            "size": 2
          }
        }
      }
    }
  }
}
```

---

## Exercice 4 — Agrégations pipeline

### 4.1 `max_bucket` — Catégorie avec le prix moyen le plus élevé

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "par_categorie": {
      "terms": { "field": "category", "size": 20 },
      "aggs": { "prix_moyen": { "avg": { "field": "price" } } }
    },
    "categorie_la_plus_chere": {
      "max_bucket": {
        "buckets_path": "par_categorie>prix_moyen"
      }
    }
  }
}
```

### 4.2 Filtres multiples avec `filters`

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "par_disponibilite": {
      "filters": {
        "filters": {
          "en_stock":       { "term": { "in_stock": true } },
          "rupture_stock":  { "term": { "in_stock": false } }
        }
      },
      "aggs": {
        "prix_moyen": { "avg": { "field": "price" } }
      }
    }
  }
}
```

---

## Exercice 5 — Combiner query et agrégation

### 5.1 Statistiques sur les produits filtrés

```
GET /products/_search
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "term": { "in_stock": true } },
        { "range": { "price": { "gte": 50, "lte": 500 } } }
      ]
    }
  },
  "aggs": {
    "par_categorie": {
      "terms": { "field": "category", "size": 10 },
      "aggs": {
        "prix_moyen": { "avg": { "field": "price" } },
        "nb_produits": { "value_count": { "field": "price" } }
      }
    }
  }
}
```

---

## Vérification finale

- [ ] `stats` et `extended_stats` calculés sur les prix
- [ ] `terms` sur `category` — distribution des catégories
- [ ] `range` sur les prix — 4 plages
- [ ] Agrégation imbriquée : prix moyen par catégorie
- [ ] `top_hits` — top 2 produits par catégorie
- [ ] `max_bucket` — catégorie la plus chère
- [ ] Requête combinée query + agrégation

*Passez au [TP12 — Dashboard e-commerce](../tp12-dashboards/README.md)*
