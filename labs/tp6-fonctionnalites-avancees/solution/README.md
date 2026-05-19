# TP6 — Solution complète : Ingest Pipelines

## Exercice 1 — Pipeline de normalisation

### Création du pipeline

```
PUT /_ingest/pipeline/pipeline-normalisation
{
  "description": "Normalisation champs produit",
  "processors": [
    { "lowercase": { "field": "category",    "ignore_missing": true } },
    { "trim":      { "field": "description", "ignore_missing": true } },
    { "convert":   { "field": "price",       "type": "float", "ignore_missing": true } }
  ]
}
```

**Réponse attendue :** `{ "acknowledged": true }`

### Explication des processors

| Processor   | Champ         | Effet                                          |
|-------------|---------------|------------------------------------------------|
| `lowercase` | `category`    | Convertit la chaîne en minuscules              |
| `trim`      | `description` | Supprime les espaces en début et fin de chaîne |
| `convert`   | `price`       | Convertit la chaîne `"299.99"` en float `299.99` |

`ignore_missing: true` évite une erreur si le champ est absent du document — indispensable en production.

### Test avec `_simulate`

`_simulate` transforme un document de test sans l'indexer. Toujours l'utiliser avant de mettre un pipeline en production.

```
POST /_ingest/pipeline/pipeline-normalisation/_simulate
{
  "docs": [
    {
      "_source": {
        "name":        "MacBook Pro",
        "category":    "ELECTRONIQUE",
        "description": "  Ordinateur portable Apple.  ",
        "price":       "299.99"
      }
    }
  ]
}
```

**Réponse attendue :**
```json
{
  "docs": [
    {
      "doc": {
        "_source": {
          "name":        "MacBook Pro",
          "category":    "electronique",
          "description": "Ordinateur portable Apple.",
          "price":       299.99
        }
      }
    }
  ]
}
```

---

## Exercice 2 — Pipeline d'enrichissement + on_failure

### Création du pipeline

```
PUT /_ingest/pipeline/pipeline-enrichissement
{
  "description": "Enrichissement et nettoyage",
  "processors": [
    {
      "set": {
        "field": "indexed_at",
        "value": "{{{_ingest.timestamp}}}",
        "on_failure": [
          { "set": { "field": "_index", "value": "failed-products" } }
        ]
      }
    },
    {
      "remove": {
        "field": "_tmp",
        "ignore_missing": true
      }
    }
  ]
}
```

**Réponse attendue :** `{ "acknowledged": true }`

### Explication des mécanismes

**`{{{_ingest.timestamp}}}`** — La syntaxe triple-accolades insère le timestamp exact du passage dans le pipeline (format ISO 8601). C'est la date d'indexation côté serveur, indépendante du contenu du document.

**`on_failure`** — Si le processor `set` échoue, OpenSearch exécute la liste `on_failure` au lieu de rejeter le document. Ici on redirige vers l'index `failed-products` pour inspection, sans perdre le document.

**`remove` + `ignore_missing: true`** — Supprime le champ temporaire `_tmp` s'il existe. Sans `ignore_missing`, le processor échouerait si `_tmp` est absent.

### Indexation avec le pipeline

```
PUT /products/_doc/test-pipeline-001?pipeline=pipeline-enrichissement
{
  "name":     "Vélo VTT Pro",
  "category": "sports",
  "price":    499.0,
  "_tmp":     "draft"
}
```

**Réponse attendue :** `{ "result": "created", "_id": "test-pipeline-001" }`

### Vérification

```
GET /products/_doc/test-pipeline-001
```

**Réponse attendue (`_source`) :**
```json
{
  "name":       "Vélo VTT Pro",
  "category":   "sports",
  "price":      499.0,
  "indexed_at": "2026-05-19T10:23:45.123456789Z"
}
```

`indexed_at` est présent et `_tmp` est absent — le pipeline a fonctionné.

---

## Exercice 3 — Processor conditionnel

### Création du pipeline

```
PUT /_ingest/pipeline/pipeline-segment
{
  "processors": [
    {
      "set": {
        "if":    "ctx.price != null && ctx.price > 500",
        "field": "segment",
        "value": "premium"
      }
    },
    {
      "set": {
        "if":    "ctx.price != null && ctx.price <= 500",
        "field": "segment",
        "value": "standard"
      }
    }
  ]
}
```

**Réponse attendue :** `{ "acknowledged": true }`

### Explication du Painless

Le champ `"if"` accepte du code Painless compilé côté serveur. `ctx` est le document en cours de traitement.

| Condition Painless                       | Valeur assignée  |
|------------------------------------------|-----------------|
| `ctx.price != null && ctx.price > 500`  | `"premium"`     |
| `ctx.price != null && ctx.price <= 500` | `"standard"`    |

La garde `!= null` est obligatoire : accéder à un champ absent sans protection lève une `NullPointerException` Painless et fait échouer le processor.

### Test avec deux documents

```
POST /_ingest/pipeline/pipeline-segment/_simulate
{
  "docs": [
    { "_source": { "name": "Laptop Pro", "price": 799 } },
    { "_source": { "name": "Souris USB",  "price": 49  } }
  ]
}
```

**Réponse attendue :**
```json
{
  "docs": [
    { "doc": { "_source": { "name": "Laptop Pro", "price": 799, "segment": "premium"  } } },
    { "doc": { "_source": { "name": "Souris USB",  "price": 49,  "segment": "standard" } } }
  ]
}
```

---

## Exercice 4 — Chaîner plusieurs pipelines

### Création du pipeline maître

```
PUT /_ingest/pipeline/pipeline-produits-complet
{
  "description": "Pipeline maître : normalisation puis enrichissement",
  "processors": [
    { "pipeline": { "name": "pipeline-normalisation"  } },
    { "pipeline": { "name": "pipeline-enrichissement" } }
  ]
}
```

**Réponse attendue :** `{ "acknowledged": true }`

### Principe du processor `pipeline`

Le processor `pipeline` appelle un autre pipeline depuis le pipeline courant. Les documents traversent les processors dans l'ordre : tous ceux de `pipeline-normalisation` d'abord, puis tous ceux de `pipeline-enrichissement`. C'est l'équivalent d'une composition de fonctions.

Avantage architectural : chaque pipeline reste petit, testable indépendamment, et réutilisable dans d'autres contextes.

### Test `_simulate` sur le pipeline maître

```
POST /_ingest/pipeline/pipeline-produits-complet/_simulate
{
  "docs": [
    {
      "_source": {
        "name":        "Casque Audio BT",
        "category":    "AUDIO",
        "description": "  Casque sans fil 30h autonomie.  ",
        "price":       "89.99",
        "_tmp":        "brouillon"
      }
    }
  ]
}
```

**Réponse attendue (`_source`) :**
```json
{
  "name":        "Casque Audio BT",
  "category":    "audio",
  "description": "Casque sans fil 30h autonomie.",
  "price":       89.99,
  "indexed_at":  "2026-05-19T10:23:45.123456789Z"
}
```

`_tmp` n'apparaît pas — supprimé par `pipeline-enrichissement`. Les quatre transformations sont appliquées en un seul appel.

### Indexation réelle avec le pipeline maître

```
PUT /products/_doc/test-master-001?pipeline=pipeline-produits-complet
{
  "name":        "Clavier mécanique RGB",
  "category":    "INFORMATIQUE",
  "description": "   Clavier TKL switches Cherry MX Red.   ",
  "price":       "129.99",
  "_tmp":        "draft"
}
```

### Vérification finale

```
GET /products/_doc/test-master-001
```

**Réponse attendue (`_source`) :**
```json
{
  "name":        "Clavier mécanique RGB",
  "category":    "informatique",
  "description": "Clavier TKL switches Cherry MX Red.",
  "price":       129.99,
  "indexed_at":  "2026-05-19T10:23:45.123456789Z"
}
```

---

## Résumé des pipelines créés

| Pipeline                    | Processors                                             | Usage                                   |
|-----------------------------|--------------------------------------------------------|-----------------------------------------|
| `pipeline-normalisation`    | `lowercase`, `trim`, `convert`                         | Nettoyage des champs à l'entrée         |
| `pipeline-enrichissement`   | `set` (indexed_at) + `on_failure`, `remove` (_tmp)     | Audit trail + suppression champs temp   |
| `pipeline-segment`          | `set` conditionnel Painless                            | Segmentation métier à l'indexation      |
| `pipeline-produits-complet` | `pipeline` → normalisation, `pipeline` → enrichissement | Orchestration des deux pipelines        |

## Concepts clés

| Concept                     | Description                                                                   |
|-----------------------------|-------------------------------------------------------------------------------|
| `_simulate`                 | Teste un pipeline sans indexer — à utiliser systématiquement avant la prod    |
| `ignore_missing: true`      | Rend le processor tolérant aux champs absents                                 |
| `{{{_ingest.timestamp}}}`   | Timestamp serveur injecté au moment du passage dans le pipeline               |
| `on_failure`                | Liste de processors de secours si le processor courant échoue                 |
| `if` (Painless)             | Condition d'exécution — `ctx` référence le document courant                  |
| processor `pipeline`        | Appelle un autre pipeline en sous-routine — permet la composition de pipelines |
