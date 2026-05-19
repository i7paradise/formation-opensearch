# TP12 — Reindex + ISM (Index State Management)

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

## Exercice 5 — ISM sur les index SpaceX (timing accéléré)

### 5.1 Créer une politique ISM pour les index SpaceX

```
PUT /_plugins/_ism/policies/spacex-lifecycle
{
  "policy": {
    "description": "Cycle de vie accéléré pour les index SpaceX (lab)",
    "ism_template": [
      { "index_patterns": ["spacex-*"], "priority": 100 }
    ],
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [],
        "transitions": [
          { "state_name": "delete", "conditions": { "min_index_age": "1min" } }
        ]
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

> Note : La transition `min_index_age: 1min` est volontairement accélérée pour le lab. En production, utilisez des valeurs réalistes (`30d`, `90d`, etc.).

### 5.2 Vérifier l'application de la politique

Attendez 1 à 2 minutes, puis vérifiez l'état de la politique sur l'index :

```
GET /_plugins/_ism/explain/spacex-launches
```

### 5.3 Vérifier la politique créée

```
GET /_plugins/_ism/policies/spacex-lifecycle
```

---

## Exercice 6 — Alias + Rollover SpaceX

### 6.1 Créer un index template pour spacex-logs

```
PUT /_index_template/spacex-template
{
  "index_patterns": ["spacex-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "name": { "type": "keyword" },
        "date_utc": { "type": "date" },
        "success": { "type": "boolean" },
        "flight_number": { "type": "integer" }
      }
    }
  }
}
```

### 6.2 Créer le premier index avec l'alias write

```
PUT /spacex-logs-000001
{
  "aliases": {
    "spacex-logs-current": {
      "is_write_index": true
    }
  }
}
```

### 6.3 Indexer 5 documents de test

```
POST /spacex-logs-current/_doc
{ "name": "Test Launch 1", "date_utc": "2024-01-01T00:00:00Z", "success": true, "flight_number": 200 }
```

```
POST /spacex-logs-current/_doc
{ "name": "Test Launch 2", "date_utc": "2024-02-01T00:00:00Z", "success": true, "flight_number": 201 }
```

```
POST /spacex-logs-current/_doc
{ "name": "Test Launch 3", "date_utc": "2024-03-01T00:00:00Z", "success": false, "flight_number": 202 }
```

```
POST /spacex-logs-current/_doc
{ "name": "Test Launch 4", "date_utc": "2024-04-01T00:00:00Z", "success": true, "flight_number": 203 }
```

```
POST /spacex-logs-current/_doc
{ "name": "Test Launch 5", "date_utc": "2024-05-01T00:00:00Z", "success": true, "flight_number": 204 }
```

### 6.4 Déclencher le rollover manuel

Rollover avec condition `max_docs: 3` — crée automatiquement `spacex-logs-000002` :

```
POST /spacex-logs-current/_rollover
{
  "conditions": {
    "max_docs": 3
  }
}
```

### 6.5 Vérifier le résultat

```
GET /_cat/aliases?v&h=alias,index,is_write_index
```

```
GET /_cat/indices/spacex-logs-*?v&h=index,docs.count,store.size
```

> Après le rollover, `spacex-logs-current` pointe vers `spacex-logs-000002` (nouveau write index). Les documents sont répartis entre les deux index.

---

## Exercice 7 — SLM (Snapshot Lifecycle Management)

### 7.1 Créer le repository de snapshots

Assurez-vous que le repository `fs-backup` existe (créé à l'Exercice 4). Si ce n'est pas le cas :

```
PUT /_snapshot/fs-backup
{
  "type": "fs",
  "settings": { "location": "/usr/share/opensearch/snapshots" }
}
```

### 7.2 Créer la politique SLM pour les index SpaceX

```
PUT /_plugins/_sm/policies/daily-spacex
{
  "description": "Snapshots quotidiens SpaceX",
  "creation": {
    "schedule": { "cron": { "expression": "0 1 * * *", "timezone": "UTC" } },
    "time_limit": "1h"
  },
  "deletion": {
    "schedule": { "cron": { "expression": "0 2 * * *", "timezone": "UTC" } },
    "time_limit": "1h",
    "condition": { "max_count": 30, "max_age": "30d" }
  },
  "snapshot_config": {
    "repository": "fs-backup",
    "indices": "spacex-*"
  }
}
```

> Cette politique crée un snapshot à 01h00 UTC chaque nuit et supprime les snapshots de plus de 30 jours ou si le nombre dépasse 30.

### 7.3 Vérifier la politique SLM

```
GET /_plugins/_sm/policies/daily-spacex/explain
```

### 7.4 Déclencher un snapshot immédiat (pour tester)

```
POST /_plugins/_sm/policies/daily-spacex/_execute
```

Vérifiez ensuite les snapshots créés :

```
GET /_snapshot/fs-backup/_all
```

---

## Vérification finale

- [ ] Alias `products-current` créé sur `products`
- [ ] `products-v2` créé avec mapping amélioré (3 shards, analyseur français)
- [ ] Reindex effectué — `products-v2` a le même nombre de documents
- [ ] Alias basculé vers `products-v2` sans interruption
- [ ] Politique ISM `logs-lifecycle` créée avec états hot/warm/delete
- [ ] Snapshot `formation-backup/snapshot-products` créé
- [ ] Politique ISM `spacex-lifecycle` créée avec `ism_template` sur `spacex-*`
- [ ] État ISM vérifié sur `spacex-launches` via `_plugins/_ism/explain`
- [ ] Index template `spacex-template` créé pour `spacex-logs-*`
- [ ] Alias `spacex-logs-current` avec rollover vers `spacex-logs-000002`
- [ ] Politique SLM `daily-spacex` créée avec schedule cron et rétention 30j
- [ ] (Bonus) Snapshot immédiat déclenché et vérifié

*Suite : [TP16 — Anomaly Detection SpaceX](../tp16-anomaly/README.md)*
