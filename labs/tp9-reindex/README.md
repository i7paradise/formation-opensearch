# TP8 — Resharding avec l'API _reindex

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 20 minutes                                           |
| Difficulté | Intermédiaire                                        |
| Prérequis  | TP7 terminé — index `products` présent avec 1000+ documents |
| Objectif   | Maîtriser le _reindex pour resharding et migration zero-downtime |

## Objectif

Apprendre à reshaper un index existant : modifier le nombre de shards, transformer les données avec Painless, et réaliser un swap d'alias sans interruption de service.

## Contexte

L'index `products` a été créé avec le nombre de shards par défaut. Après analyse du volume de données, on décide de passer à 3 shards primaires pour améliorer la distribution. On utilisera l'API `_reindex` pour migrer les données et un alias pour le swap zero-downtime.

---

## Exercice 1 — Préparer le nouvel index

### 1.1 Vérifier l'état de l'index source

```
GET /products/_settings
```

```
GET /_cat/shards/products?v&h=index,shard,prirep,docs,store,node
```

### 1.2 Créer `products-v2` avec 3 shards

```
PUT /products-v2
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1
  },
  "mappings": {
    "properties": {
      "name":        { "type": "text", "fields": { "raw": { "type": "keyword" } } },
      "category":    { "type": "keyword" },
      "price":       { "type": "float" },
      "description": { "type": "text" },
      "in_stock":    { "type": "boolean" },
      "created_at":  { "type": "date" }
    }
  }
}
```

---

## Exercice 2 — _reindex avec transformation Painless

### 2.1 Réindexer en ajoutant le champ `migrated_at`

```
POST /_reindex
{
  "source": {
    "index": "products"
  },
  "dest": {
    "index": "products-v2"
  },
  "script": {
    "source": "ctx._source.migrated_at = params.ts",
    "params": { "ts": "2025-01-01T00:00:00Z" }
  }
}
```

**Résultat attendu** : `created`, `updated`, `failed`, `took` dans la réponse.

### 2.2 Vérifier la migration

```
GET /_cat/shards/products-v2?v&h=index,shard,prirep,docs,store,node
```

```
GET /products-v2/_search
{
  "size": 1,
  "_source": ["name", "migrated_at"]
}
```

---

## Exercice 3 — Swap d'alias zero-downtime

### 3.1 Créer l'alias sur l'index source (si pas déjà fait)

```
POST /_aliases
{
  "actions": [
    { "add": { "index": "products", "alias": "products-current" } }
  ]
}
```

### 3.2 Swap atomique : products → products-v2

```
POST /_aliases
{
  "actions": [
    { "remove": { "index": "products",    "alias": "products-current" } },
    { "add":    { "index": "products-v2", "alias": "products-current" } }
  ]
}
```

### 3.3 Vérifier que l'alias pointe vers products-v2

```
GET /_cat/aliases/products-current?v
```

```
GET /products-current/_count
```

**Observation** : l'alias est déplacé atomiquement — aucune requête n'est perdue pendant le swap.

---

## Exercice 4 — Vérification finale

```
GET /_cat/shards/products-v2?v
```

Comparer avec `GET /_cat/shards/products?v` : le nombre de shards primaires est passé de 1 à 3.

---

## ⭐ Bonus — Mode async + monitor _tasks

### Mode asynchrone (utile sur gros volumes)

```
POST /_reindex?wait_for_completion=false
{
  "source": { "index": "products-v2" },
  "dest":   { "index": "products-v3" }
}
```

Récupérer le `task` ID dans la réponse, puis :

```
GET /_tasks/<task-id>
```

Pour annuler :

```
POST /_tasks/<task-id>/_cancel
```

### Paralléliser avec slices

```
POST /_reindex
{
  "source":  { "index": "products" },
  "dest":    { "index": "products-v2" },
  "slices":  "auto"
}
```

`slices: auto` parallélise le reindex par shard — divise le temps de migration proportionnellement au nombre de shards primaires de la source.

### Monitor les tâches en cours

```
GET /_cat/tasks?v&actions=*reindex
```

---

## Passez au TP10 — Routage

→ [TP10 — Routage : définir et utiliser le routing](../tp10-routing/README.md)
