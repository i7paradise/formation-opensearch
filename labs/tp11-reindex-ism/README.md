# TP11 — Reindex + ISM (Index State Management)

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 30 minutes                                           |
| Difficulté | Avancé                                               |
| Prérequis  | TP10 terminé — cluster 3 nœuds, index `products` avec données |
| Objectif   | Reindexer sans interruption de service + automatiser le cycle de vie des index |

## Objectif

Maîtriser deux opérations indispensables en production :
1. **Reindex** : changer le mapping ou le nombre de shards sans interruption de service via les aliases
2. **ISM** : automatiser la rotation et la suppression des vieux index

---

## Exercice 1 — Reindex API

### 1.1 Créer un alias sur l'index existant

```
POST /_aliases
{
  "actions": [
    { "add": { "index": "products", "alias": "products-current", "is_write_index": true } }
  ]
}
```

> Les applications utilisent l'alias `products-current` — elles ne connaissent pas le nom réel de l'index.

### 1.2 Créer un nouvel index avec un mapping amélioré

```
PUT /products-v2
{
  "settings": { "number_of_shards": 3, "number_of_replicas": 1 },
  "mappings": {
    "properties": {
      "name":        { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
      "description": { "type": "text", "analyzer": "french" },
      "category":    { "type": "keyword" },
      "price":       { "type": "float" },
      "in_stock":    { "type": "boolean" },
      "rating":      { "type": "float" },
      "created_at":  { "type": "date" },
      "tags":        { "type": "keyword" }
    }
  }
}
```

### 1.3 Reindexer les données

```
POST /_reindex?wait_for_completion=false
{
  "source": { "index": "products" },
  "dest":   { "index": "products-v2" }
}
```

### 1.4 Vérifier la progression

```
GET /_tasks?actions=*reindex&detailed=true
```

### 1.5 Basculer l'alias (zero-downtime)

```
POST /_aliases
{
  "actions": [
    { "remove": { "index": "products",    "alias": "products-current" } },
    { "add":    { "index": "products-v2", "alias": "products-current", "is_write_index": true } }
  ]
}
```

> Le basculement est atomique — les applications continuent à utiliser `products-current` sans interruption.

---

## Exercice 2 — Reindex avec transformation (script Painless)

```
POST /_reindex
{
  "source": { "index": "products-v2", "size": 100 },
  "dest":   { "index": "products-v3" },
  "script": {
    "source": "ctx._source.price_category = ctx._source.price < 50 ? 'budget' : (ctx._source.price < 200 ? 'mid-range' : 'premium'); ctx._source.indexed_at = params.now",
    "lang": "painless",
    "params": { "now": "2026-05-11T00:00:00Z" }
  }
}
```

---

## Exercice 3 — Politique ISM (Index State Management)

### 3.1 Créer une politique ISM de rotation automatique

```
PUT /_plugins/_ism/policies/logs-lifecycle
{
  "policy": {
    "description": "Politique de cycle de vie pour les index logs",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [
          { "rollover": { "min_doc_count": 1000, "min_size": "1gb", "min_index_age": "1d" } }
        ],
        "transitions": [{ "state_name": "warm", "conditions": { "min_index_age": "2d" } }]
      },
      {
        "name": "warm",
        "actions": [
          { "replica_count": { "number_of_replicas": 0 } },
          { "force_merge": { "max_num_segments": 1 } }
        ],
        "transitions": [{ "state_name": "delete", "conditions": { "min_index_age": "7d" } }]
      },
      {
        "name": "delete",
        "actions": [{ "delete": {} }],
        "transitions": []
      }
    ]
  }
}
```

### 3.2 Vérifier la politique

```
GET /_plugins/_ism/policies/logs-lifecycle
```

---

## Exercice 4 — Snapshot (résumé)

```
PUT /_snapshot/formation-backup
{
  "type": "fs",
  "settings": { "location": "/usr/share/opensearch/snapshots" }
}
```

```
PUT /_snapshot/formation-backup/snapshot-products?wait_for_completion=true
{
  "indices": "products,products-v2",
  "include_global_state": false
}
```

> **Règle** : Les replicas protègent contre la perte d'un nœud. Seul un snapshot protège contre les suppressions accidentelles.

---

## Vérification finale

- [ ] Alias `products-current` créé sur `products`
- [ ] `products-v2` créé avec mapping amélioré (3 shards, analyseur français)
- [ ] Reindex effectué — `products-v2` a le même nombre de documents
- [ ] Alias basculé vers `products-v2` sans interruption
- [ ] Politique ISM `logs-lifecycle` créée avec états hot/warm/delete
- [ ] (Bonus) Snapshot créé avec succès

*Fin du TP11 — Fin de la formation OpenSearch 3.6 !*
