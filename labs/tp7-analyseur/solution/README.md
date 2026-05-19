# TP7 — Solution complète : Analyseur français

## Exercice 1 — Constater le problème

### Recherche sans analyseur adapté

```
POST /products/_search
{
  "query": { "match": { "name": "velo" } },
  "size": 0
}
```

**Réponse attendue :** `{ "hits": { "total": { "value": 0 } } }`

```
POST /products/_search
{
  "query": { "match": { "name": "vélos" } },
  "size": 0
}
```

**Réponse attendue :** quelques résultats (correspondance exacte sur le token `vélos`).

### Observation

`velo` retourne 0 résultats. L'analyseur `standard` par défaut conserve les accents (`Vélos` → token `vélos`) et ne fait aucune stemmatisation. `velo` ≠ `vélos` pour le moteur.

---

## Exercice 2 — Comprendre la cause avec `_analyze`

### Analyseur standard (actuel)

```
POST /products/_analyze
{
  "analyzer": "standard",
  "text": "Vélos électriques d'entrée de gamme"
}
```

**Tokens produits :**
```json
["vélos", "électriques", "d", "entrée", "de", "gamme"]
```

`velo` n'apparaît pas : les accents sont conservés, les mots vides sont gardés, aucun stemming.

### Analyseur `french` built-in

```
POST /_analyze
{
  "analyzer": "french",
  "text": "Vélos électriques d'entrée de gamme"
}
```

**Tokens produits :**
```json
["velo", "electr", "entré", "gam"]
```

### Comparaison

| Étape              | `standard`                             | `french`                       |
|--------------------|----------------------------------------|--------------------------------|
| Tokenisation       | espaces / ponctuation                  | espaces / ponctuation          |
| Lowercase          | oui (`Vélos` → `vélos`)               | oui                            |
| Suppression accents| **non** (`vélos` reste `vélos`)       | **oui** (`vélos` → `velos`)   |
| Mots vides         | **non** (`de`, `d` conservés)         | **oui** (supprimés)            |
| Stemming           | **non** (`vélos` reste `vélos`)       | **oui** (`velos` → `velo`)    |

Conclusion : pour que `velo` matche `Vélos`, il faut les trois étapes manquantes : suppression d'accents, stop words et stemming.

---

## Exercice 3 — Créer l'analyseur français personnalisé

### Création de l'index `products-fr`

```
PUT /products-fr
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "analysis": {
      "filter": {
        "french_stop": {
          "type":      "stop",
          "stopwords": "_french_"
        },
        "french_stemmer": {
          "type":     "stemmer",
          "language": "french"
        }
      },
      "analyzer": {
        "french_custom": {
          "type":      "custom",
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
      "name":           { "type": "text",    "analyzer": "french_custom",
                          "fields": { "keyword": { "type": "keyword" } } },
      "description":    { "type": "text",    "analyzer": "french_custom" },
      "category":       { "type": "keyword" },
      "sub_category":   { "type": "keyword" },
      "brand":          { "type": "keyword" },
      "price":          { "type": "float"   },
      "original_price": { "type": "float"   },
      "in_stock":       { "type": "boolean" },
      "stock_quantity": { "type": "integer" },
      "rating":         { "type": "float"   },
      "reviews_count":  { "type": "integer" },
      "tags":           { "type": "keyword" },
      "created_at":     { "type": "date"    },
      "updated_at":     { "type": "date"    },
      "seller":         { "type": "keyword" },
      "color":          { "type": "keyword" }
    }
  }
}
```

**Réponse attendue :** `{ "acknowledged": true }`

### Pipeline de l'analyseur `french_custom`

```
standard tokenizer  →  "Vélos" "électriques" "d" "entrée" "de" "gamme"
       ↓
   lowercase        →  "vélos" "électriques" "d" "entrée" "de" "gamme"
       ↓
  asciifolding      →  "velos" "electriques" "d" "entree" "de" "gamme"
       ↓
  french_stop       →  "velos" "electriques" "entree" "gamme"
       ↓
 french_stemmer     →  "velo"  "electr"       "entré"  "gam"
```

L'ordre des filtres est important : `asciifolding` doit précéder `french_stop` et `french_stemmer` pour que ceux-ci travaillent sur des tokens déjà normalisés.

### Vérification de l'analyseur

```
POST /products-fr/_analyze
{
  "analyzer": "french_custom",
  "text": "Vélos électriques d'entrée de gamme"
}
```

**Tokens attendus :**
```json
["velo", "electr", "entré", "gam"]
```

`de`, `d` ont disparu (stop words). `Vélos` est réduit à `velo` (accent supprimé + stemming).

---

## Exercice 4 — Réindexer les données

```
POST /_reindex?wait_for_completion=true
{
  "source": { "index": "products"    },
  "dest":   { "index": "products-fr" }
}
```

**Réponse attendue :**
```json
{
  "total":   1000,
  "created": 1000,
  "updated": 0,
  "failures": []
}
```

`_reindex` copie les documents source tels quels. L'analyseur `french_custom` s'applique à l'indexation dans `products-fr` — les tokens sont recalculés au moment de l'écriture.

### Vérification des counts

```
GET /products/_count
```

```
GET /products-fr/_count
```

Les deux doivent retourner le même nombre.

### Comparer les mappings sur `name`

```
GET /products/_mapping
```

```
GET /products-fr/_mapping
```

Dans `products`, `name` utilise l'analyseur `standard` (par défaut). Dans `products-fr`, il utilise `french_custom`.

---

## Exercice 5 — Constater le résultat

### Avant : `velo` dans `products`

```
POST /products/_search
{
  "query": { "match": { "name": "velo" } },
  "size": 0
}
```

**Résultat : 0** — l'analyseur standard n'a pas produit le token `velo` à l'indexation.

### Après : `velo` dans `products-fr`

```
POST /products-fr/_search
{
  "query": { "match": { "name": "velo" } },
  "size": 5
}
```

**Résultat : 10+ résultats.** À la recherche, `velo` passe par le même analyseur `french_custom` → token `velo`, qui matche les tokens `velo` indexés depuis `Vélo`, `Vélos`, `vélo VTT`, etc.

### Bonus : sans accent

```
POST /products-fr/_search
{
  "query": { "match": { "name": "electrique" } },
  "size": 0
}
```

`electrique` → token `electr` (via asciifolding + stemmer) → matche les documents contenant `électrique`, `électriques`.

### Bonus : singulier matche pluriel

```
POST /products-fr/_search
{
  "query": { "match": { "name": "ordinateur" } },
  "size": 0
}
```

`ordinateur` → token `ordinat` → matche `ordinateur`, `ordinateurs`, `ordinateurs portables`.

---

## Résumé

| Index         | Analyseur       | Requête `velo` | Requête `electrique` |
|---------------|-----------------|---------------|----------------------|
| `products`    | `standard`      | 0 résultats   | 0 résultats          |
| `products-fr` | `french_custom` | 10+ résultats | 10+ résultats        |

## Concepts clés

| Concept        | Description                                                                      |
|----------------|----------------------------------------------------------------------------------|
| `_analyze`     | Inspecte les tokens produits par un analyseur sans indexer — outil de diagnostic |
| `asciifolding` | Supprime les accents : `é→e`, `à→a`, `ô→o`                                      |
| `stop`         | Supprime les mots vides : `de`, `le`, `la`, `un`, `d`…                          |
| `stemmer`      | Réduit les mots à leur racine : `vélos` → `velo`, `électriques` → `electr`     |
| `_reindex`     | Copie les documents d'un index vers un autre — l'analyseur cible s'applique à l'écriture |
| Analyse symétrique | Le même analyseur doit s'appliquer à l'indexation ET à la recherche pour que les tokens se correspondent |
