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

```bash
curl -s -X PUT "http://localhost:9200/products-suggest" \
  -H 'Content-Type: application/json' \
  -d '{
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
  }' | python3 -m json.tool
```

---

## Exercice 2 — Indexer des produits avec suggestions

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
' | python3 -m json.tool
```

---

## Exercice 3 — Requête de complétion basique

```bash
curl -s -X GET "http://localhost:9200/products-suggest/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "suggest": {
      "product-suggest": {
        "prefix": "smart",
        "completion": {
          "field": "suggest",
          "size": 5
        }
      }
    }
  }' | python3 -m json.tool
```

Essayez d'autres préfixes : `"cas"`, `"ord"`, `"mon"`.

---

## Exercice 4 — Completion avec fuzzy (tolérance aux fautes de frappe)

```bash
curl -s -X GET "http://localhost:9200/products-suggest/_search" \
  -H 'Content-Type: application/json' \
  -d '{
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
  }' | python3 -m json.tool
```

> Notez que "smartphne" (avec une faute) trouve quand même "Smartphone" grâce à `fuzziness: 1`.

---

## Exercice 5 — Complétion avec contexte (filtrage par catégorie)

```bash
# D'abord, créer un index avec contexte de catégorie
curl -s -X PUT "http://localhost:9200/products-suggest-ctx" \
  -H 'Content-Type: application/json' \
  -d '{
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
  }' | python3 -m json.tool

# Indexer un produit avec contexte
curl -s -X PUT "http://localhost:9200/products-suggest-ctx/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Smartphone Pro",
    "category_ctx": "Électronique",
    "suggest": {
      "input": ["Smartphone", "téléphone"],
      "contexts": { "category": "Électronique" }
    }
  }' | python3 -m json.tool

# Chercher uniquement dans la catégorie Électronique
curl -s -X GET "http://localhost:9200/products-suggest-ctx/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "suggest": {
      "product-ctx": {
        "prefix": "smart",
        "completion": {
          "field": "suggest",
          "contexts": { "category": "Électronique" }
        }
      }
    }
  }' | python3 -m json.tool
```

---

## Vérification finale

- [ ] Index `products-suggest` créé avec champ `completion`
- [ ] 5 produits indexés avec des `input` multiples et des `weight`
- [ ] Complétion basique fonctionne (prefix "smart" → Smartphone)
- [ ] Fuzzy completion tolère une faute de frappe
- [ ] (Bonus) Complétion avec contexte de catégorie
