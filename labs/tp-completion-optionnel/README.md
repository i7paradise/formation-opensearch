# TP Optionnel — Autocomplétion avec le Completion Suggester

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 30 minutes                                           |
| Niveau     | Optionnel — pour aller plus loin                     |
| Prérequis  | TP2 terminé                                          |
| Objectif   | Completion suggester, fuzzy completion, autocomplétion |

## Objectif

Implémenter une barre de recherche avec autocomplétion en temps réel sur les noms de produits.

---

## Exercice 1 — Créer un index avec champ `completion`

```
PUT /products-suggest
{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": {
    "properties": {
      "name":     { "type": "text" },
      "category": { "type": "keyword" },
      "price":    { "type": "float" },
      "suggest": {
        "type": "completion",
        "analyzer": "simple",
        "preserve_separators": true,
        "preserve_position_increments": true,
        "max_input_length": 50
      }
    }
  }
}
```

---

## Exercice 2 — Indexer des produits avec suggestions

> **Note** : Le chargement de fichiers NDJSON se fait via curl, pas depuis le Dev Console.

```bash
curl -s -X POST "http://localhost:9200/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  -d '{"index":{"_index":"products-suggest","_id":"1"}}
{"name":"Smartphone Pro Max 256Go","category":"Électronique","price":899.99,"suggest":{"input":["Smartphone Pro Max","Smartphone","Pro Max 256Go","téléphone"],"weight":10}}
{"index":{"_index":"products-suggest","_id":"2"}}
{"name":"Casque Audio Sans Fil Bluetooth","category":"Audio","price":199.99,"suggest":{"input":["Casque Audio","Casque Bluetooth","casque sans fil","écouteurs"],"weight":8}}
{"index":{"_index":"products-suggest","_id":"3"}}
{"name":"Ordinateur Portable Ultrabook 15","category":"Informatique","price":1299.0,"suggest":{"input":["Ordinateur Portable","Laptop","Ultrabook","PC portable"],"weight":9}}
{"index":{"_index":"products-suggest","_id":"4"}}
{"name":"Montre Connectée Sport GPS","category":"Montres","price":349.0,"suggest":{"input":["Montre Connectée","Smartwatch","montre GPS","montre sport"],"weight":7}}
{"index":{"_index":"products-suggest","_id":"5"}}
{"name":"Tablette Graphique Creative Pro","category":"Informatique","price":249.0,"suggest":{"input":["Tablette Graphique","tablette créative","tablette dessin"],"weight":6}}
'
```

---

## Exercice 3 — Requête de complétion basique

```
GET /products-suggest/_search
{
  "suggest": {
    "product-suggest": {
      "prefix": "smart",
      "completion": {
        "field": "suggest",
        "size": 5
      }
    }
  }
}
```

Essayez d'autres préfixes : `"cas"`, `"ord"`, `"mon"`.

---

## Exercice 4 — Completion avec fuzzy (tolérance aux fautes de frappe)

```
GET /products-suggest/_search
{
  "suggest": {
    "product-suggest-fuzzy": {
      "prefix": "smartphne",
      "completion": {
        "field": "suggest",
        "size": 5,
        "fuzzy": {
          "fuzziness": 1,
          "min_length": 4,
          "prefix_length": 2
        }
      }
    }
  }
}
```

> Notez que "smartphne" (avec une faute) trouve quand même "Smartphone" grâce à `fuzziness: 1`.

---

## Exercice 5 — Complétion avec contexte (filtrage par catégorie)

```
PUT /products-suggest-ctx
{
  "mappings": {
    "properties": {
      "name": { "type": "text" },
      "suggest": {
        "type": "completion",
        "contexts": [
          { "name": "category", "type": "category", "path": "category_ctx" }
        ]
      },
      "category_ctx": { "type": "keyword" }
    }
  }
}
```

```
PUT /products-suggest-ctx/_doc/1
{
  "name": "Smartphone Pro",
  "category_ctx": "Électronique",
  "suggest": {
    "input": ["Smartphone", "téléphone"],
    "contexts": { "category": "Électronique" }
  }
}
```

```
GET /products-suggest-ctx/_search
{
  "suggest": {
    "product-ctx": {
      "prefix": "smart",
      "completion": {
        "field": "suggest",
        "contexts": { "category": "Électronique" }
      }
    }
  }
}
```

---

## Vérification finale

- [ ] Index `products-suggest` créé avec champ `completion`
- [ ] 5 produits indexés avec des `input` multiples et des `weight`
- [ ] Complétion basique fonctionne (prefix "smart" → Smartphone)
- [ ] Fuzzy completion tolère une faute de frappe
- [ ] (Bonus) Complétion avec contexte de catégorie
