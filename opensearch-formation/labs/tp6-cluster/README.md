# TP6 — Cluster OpenSearch multi-nœuds en production

## Informations générales

| Paramètre  | Valeur                                      |
|------------|---------------------------------------------|
| Durée      | 60 minutes                                  |
| Difficulté | Avancé                                      |
| Prérequis  | TP5 terminé                                 |
| Objectif   | Cluster 3 nœuds en haute disponibilité      |

## Objectif

Configurer et gérer un cluster OpenSearch multi-nœuds en configuration de production. Vous allez passer d'un nœud unique à un cluster de 3 nœuds, puis configurer les mécanismes de résilience : templates d'index, aliases, snapshots et politiques ISM (Index State Management).

## Contexte

Notre moteur de recherche e-commerce est actuellement sur un nœud unique — une configuration inacceptable pour la production. Une panne du serveur entraînerait une indisponibilité totale. Vous allez migrer vers une architecture haute disponibilité.

## Architecture cible

```
┌─────────────────────────────────────────────────────┐
│                  Cluster OpenSearch                  │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│  │  opensearch  │  │ opensearch-2 │  │opensearch│  │
│  │  -node1      │  │              │  │  -node3  │  │
│  │  (master +   │  │ (data +      │  │ (data +  │  │
│  │   data)      │  │  ingest)     │  │  ingest) │  │
│  │  port: 9200  │  │  port: 9201  │  │  port:   │  │
│  │              │  │              │  │  9202    │  │
│  └──────────────┘  └──────────────┘  └──────────┘  │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │         OpenSearch Dashboards               │   │
│  │              port: 5601                     │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## Exercice 1 — Basculer vers le cluster multi-nœuds

### 1.1 Arrêter l'environnement mono-nœud

```bash
cd /chemin/vers/formation-opensearch/infrastructure
docker compose down
```

### 1.2 Vérifier le fichier docker-compose.cluster.yml

Le fichier `docker-compose.cluster.yml` configure 3 nœuds OpenSearch et 1 instance Dashboards. Vérifiez les points clés :

```bash
cat infrastructure/docker-compose.cluster.yml
```

Variables importantes à observer :
- `cluster.name` : identique sur les 3 nœuds (`opensearch-cluster`)
- `node.name` : unique par nœud (`opensearch-node1`, `opensearch-node2`, `opensearch-node3`)
- `discovery.seed_hosts` : liste des nœuds à contacter pour la découverte
- `cluster.initial_cluster_manager_nodes` : nœud(s) éligibles comme cluster manager
- `OPENSEARCH_JAVA_OPTS` : mémoire JVM (`-Xms512m -Xmx512m` en démo, 50% RAM en production)

### 1.3 Démarrer le cluster

```bash
docker compose -f infrastructure/docker-compose.cluster.yml up -d
```

### 1.4 Attendre le démarrage (environ 60 secondes)

```bash
# Attendre que le cluster soit prêt
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; do
  echo "En attente du cluster..."
  sleep 5
done
echo "Cluster prêt !"
```

### 1.5 Vérifier l'état du cluster

```bash
curl -X GET "http://localhost:9200/_cluster/health?pretty"
```

**Résultat attendu :**
```json
{
  "cluster_name" : "opensearch-cluster",
  "status" : "green",
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : ...,
  "active_shards" : ...,
  "relocating_shards" : 0,
  "unassigned_shards" : 0
}
```

> **Attention** : Le statut peut être `yellow` si des index ont des réplicas non assignés. C'est normal si un seul nœud est disponible. Il doit passer à `green` avec 3 nœuds.

---

## Exercice 2 — Vérifier la distribution des shards

### 2.1 Lister tous les shards

```bash
curl -X GET "http://localhost:9200/_cat/shards?v&pretty"
```

Cette commande affiche pour chaque shard :
- `index` : nom de l'index
- `shard` : numéro du shard (0, 1, 2...)
- `prirep` : `p` pour primaire, `r` pour réplique
- `state` : `STARTED`, `INITIALIZING`, `UNASSIGNED`
- `node` : nœud qui héberge le shard

**Question :** Les shards primaires et répliques sont-ils sur des nœuds différents ?

### 2.2 Vérifier l'allocation

```bash
curl -X GET "http://localhost:9200/_cat/allocation?v&pretty"
```

Affiche par nœud :
- `shards` : nombre de shards hébergés
- `disk.used` : espace disque utilisé
- `disk.avail` : espace disponible
- `disk.percent` : pourcentage d'utilisation

**Vérification :** Les shards doivent être équilibrés entre les nœuds.

### 2.3 Vérifier les nœuds du cluster

```bash
curl -X GET "http://localhost:9200/_cat/nodes?v&h=name,ip,heap.percent,ram.percent,cpu,master,node.role&pretty"
```

Le symbole `*` dans la colonne `master` indique le nœud cluster manager actuel.

---

## Exercice 3 — Créer un Index Template pour `products-*`

Les index templates permettent d'appliquer automatiquement un mapping et des paramètres à tout nouvel index correspondant à un pattern.

### 3.1 Créer un composant template pour le mapping

```bash
curl -X PUT "http://localhost:9200/_component_template/products-mappings" \
  -H "Content-Type: application/json" \
  -d '{
    "template": {
      "mappings": {
        "properties": {
          "name":           { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
          "description":    { "type": "text", "analyzer": "french" },
          "category":       { "type": "keyword" },
          "brand":          { "type": "keyword" },
          "price":          { "type": "float" },
          "stock_quantity": { "type": "integer" },
          "rating":         { "type": "float" },
          "created_at":     { "type": "date", "format": "strict_date_optional_time||epoch_millis" },
          "tags":           { "type": "keyword" }
        }
      }
    }
  }'
```

### 3.2 Créer un composant template pour les paramètres

```bash
curl -X PUT "http://localhost:9200/_component_template/products-settings" \
  -H "Content-Type: application/json" \
  -d '{
    "template": {
      "settings": {
        "number_of_shards":   3,
        "number_of_replicas": 1,
        "refresh_interval":   "1s",
        "analysis": {
          "analyzer": {
            "french_custom": {
              "type":      "custom",
              "tokenizer": "standard",
              "filter":    ["lowercase", "french_stop", "french_stemmer"]
            }
          },
          "filter": {
            "french_stop":    { "type": "stop",   "stopwords": "_french_" },
            "french_stemmer": { "type": "stemmer", "language": "light_french" }
          }
        }
      }
    }
  }'
```

### 3.3 Créer l'index template composite

```bash
curl -X PUT "http://localhost:9200/_index_template/products-template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["products-*"],
    "priority": 100,
    "composed_of": ["products-mappings", "products-settings"],
    "template": {
      "aliases": {
        "products-all": {}
      }
    },
    "_meta": {
      "description": "Template pour les index produits e-commerce",
      "version": "1.0"
    }
  }'
```

### 3.4 Tester le template

```bash
# Créer un index qui correspond au pattern
curl -X PUT "http://localhost:9200/products-2026-01" -H "Content-Type: application/json" -d '{}'

# Vérifier que le mapping a été appliqué automatiquement
curl -X GET "http://localhost:9200/products-2026-01/_mapping?pretty"

# Vérifier que l'alias a été créé
curl -X GET "http://localhost:9200/products-2026-01/_alias?pretty"
```

---

## Exercice 4 — Configurer des aliases (basculement sans interruption)

Les aliases permettent de faire pointer un nom logique vers un ou plusieurs index physiques. Pratique pour les migrations sans downtime.

### 4.1 Préparer deux versions de l'index products

```bash
# Indexer quelques documents dans products-v1
curl -X POST "http://localhost:9200/products-v1/_bulk" \
  -H "Content-Type: application/json" \
  -d '
{"index":{"_id":"1"}}
{"name":"Smartphone Alpha","category":"Électronique","price":599.99,"created_at":"2026-01-01"}
{"index":{"_id":"2"}}
{"name":"Laptop Pro","category":"Électronique","price":1299.99,"created_at":"2026-01-02"}
{"index":{"_id":"3"}}
{"name":"T-shirt Coton","category":"Vêtements","price":24.99,"created_at":"2026-01-03"}
'
```

### 4.2 Créer l'alias pointant sur v1

```bash
curl -X POST "http://localhost:9200/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      {
        "add": {
          "index": "products-v1",
          "alias": "products-current",
          "is_write_index": true
        }
      }
    ]
  }'
```

### 4.3 Vérifier que l'alias fonctionne

```bash
# Requête via l'alias (transparent pour les clients)
curl -X GET "http://localhost:9200/products-current/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} }, "size": 3 }'
```

### 4.4 Préparer la v2 avec le nouveau mapping

```bash
# Créer products-v2 avec un champ supplémentaire
curl -X PUT "http://localhost:9200/products-v2" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": { "number_of_shards": 3, "number_of_replicas": 1 },
    "mappings": {
      "properties": {
        "name":         { "type": "text" },
        "category":     { "type": "keyword" },
        "price":        { "type": "float" },
        "created_at":   { "type": "date" },
        "availability": { "type": "keyword" }
      }
    }
  }'

# Réindexer les données de v1 vers v2
curl -X POST "http://localhost:9200/_reindex" \
  -H "Content-Type: application/json" \
  -d '{
    "source": { "index": "products-v1" },
    "dest":   { "index": "products-v2" }
  }'
```

### 4.5 Basculement atomique v1 → v2 (zero-downtime)

```bash
curl -X POST "http://localhost:9200/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      {
        "remove": {
          "index": "products-v1",
          "alias": "products-current"
        }
      },
      {
        "add": {
          "index": "products-v2",
          "alias": "products-current",
          "is_write_index": true
        }
      }
    ]
  }'
```

> **Clé** : Les actions `remove` et `add` sont atomiques — aucune fenêtre d'indisponibilité.

### 4.6 Vérifier le basculement

```bash
curl -X GET "http://localhost:9200/_cat/aliases?v&pretty"
curl -X GET "http://localhost:9200/products-current/_count"
```

---

## Exercice 5 — Créer un snapshot (sauvegarde)

### 5.1 Enregistrer un repository de type filesystem

```bash
curl -X PUT "http://localhost:9200/_snapshot/backup-repo" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/mnt/snapshots",
      "compress": true,
      "max_snapshot_bytes_per_sec": "50mb",
      "max_restore_bytes_per_sec":  "50mb"
    }
  }'
```

> **Note** : Le répertoire `/mnt/snapshots` doit être monté dans tous les nœuds Docker (voir `docker-compose.cluster.yml`, volume `opensearch-snapshots`).

### 5.2 Vérifier le repository

```bash
curl -X POST "http://localhost:9200/_snapshot/backup-repo/_verify?pretty"
```

**Résultat attendu :** La réponse liste les 3 nœuds qui ont accès au repository.

### 5.3 Créer un snapshot

```bash
curl -X PUT "http://localhost:9200/_snapshot/backup-repo/snapshot-products-2026-01-15" \
  -H "Content-Type: application/json" \
  -d '{
    "indices":             "products-*,products",
    "ignore_unavailable":  true,
    "include_global_state": false,
    "metadata": {
      "taken_by":   "formation-tp6",
      "taken_because": "Sauvegarde avant migration v2"
    }
  }'
```

### 5.4 Suivre la progression

```bash
curl -X GET "http://localhost:9200/_snapshot/backup-repo/snapshot-products-2026-01-15?pretty"
```

Attendez que `state` passe à `SUCCESS`.

### 5.5 Lister les snapshots disponibles

```bash
curl -X GET "http://localhost:9200/_snapshot/backup-repo/_all?pretty"
```

### 5.6 (Optionnel) Tester la restauration

```bash
# Supprimer l'index de test
curl -X DELETE "http://localhost:9200/products-v1"

# Restaurer depuis le snapshot
curl -X POST "http://localhost:9200/_snapshot/backup-repo/snapshot-products-2026-01-15/_restore" \
  -H "Content-Type: application/json" \
  -d '{
    "indices":              "products-v1",
    "ignore_unavailable":   true,
    "include_global_state": false,
    "rename_pattern":       "(.+)",
    "rename_replacement":   "$1-restored"
  }'

# Vérifier
curl -X GET "http://localhost:9200/products-v1-restored/_count"
```

---

## Exercice 6 — Configurer une politique ISM (hot → delete)

ISM (Index State Management) permet d'automatiser le cycle de vie des index.

### 6.1 Créer la politique ISM

```bash
curl -X PUT "http://localhost:9200/_plugins/_ism/policies/products-lifecycle" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "description": "Politique de cycle de vie pour les index produits",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [
            {
              "rollover": {
                "min_index_age": "7d",
                "min_doc_count":  10000,
                "min_size":       "5gb"
              }
            }
          ],
          "transitions": [
            {
              "state_name": "warm",
              "conditions": { "min_index_age": "7d" }
            }
          ]
        },
        {
          "name": "warm",
          "actions": [
            {
              "replica_count": { "number_of_replicas": 0 }
            },
            {
              "index_priority": { "priority": 50 }
            }
          ],
          "transitions": [
            {
              "state_name": "delete",
              "conditions": { "min_index_age": "30d" }
            }
          ]
        },
        {
          "name": "delete",
          "actions": [
            {
              "delete": {}
            }
          ],
          "transitions": []
        }
      ],
      "ism_template": [
        {
          "index_patterns": ["products-*"],
          "priority": 100
        }
      ]
    }
  }'
```

### 6.2 Vérifier la politique

```bash
curl -X GET "http://localhost:9200/_plugins/_ism/policies/products-lifecycle?pretty"
```

### 6.3 Attacher manuellement la politique à un index

```bash
curl -X POST "http://localhost:9200/_plugins/_ism/add/products-2026-01" \
  -H "Content-Type: application/json" \
  -d '{
    "policy_id": "products-lifecycle"
  }'
```

### 6.4 Vérifier l'état ISM de l'index

```bash
curl -X GET "http://localhost:9200/_plugins/_ism/explain/products-2026-01?pretty"
```

---

## Exercice 7 — Monitorer le cluster

### 7.1 Statistiques des nœuds

```bash
# Statistiques complètes de tous les nœuds
curl -X GET "http://localhost:9200/_nodes/stats?pretty" | head -100

# Statistiques filtrées (JVM, indices, OS)
curl -X GET "http://localhost:9200/_nodes/stats/jvm,indices,os?pretty"
```

Métriques importantes à observer :
- `jvm.heap_used_percent` : utilisation du heap JVM (alerte si > 75%)
- `indices.indexing.index_total` : nombre total d'indexations
- `indices.search.query_total` : nombre total de requêtes
- `os.cpu.percent` : utilisation CPU

### 7.2 Vue synthétique des nœuds

```bash
curl -X GET "http://localhost:9200/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu,load_1m,master,node.role&pretty"
```

### 7.3 Statistiques du cluster

```bash
curl -X GET "http://localhost:9200/_cluster/stats?pretty"
```

### 7.4 Monitoring des performances des index

```bash
curl -X GET "http://localhost:9200/products/_stats?pretty"
```

Observez :
- `_all.primaries.indexing.index_total` : documents indexés
- `_all.primaries.search.query_time_in_millis` : temps cumulé de recherche
- `_all.primaries.merges.total` : nombre de merges Lucene

### 7.5 Vérifier les tâches en cours

```bash
curl -X GET "http://localhost:9200/_tasks?actions=*search*&pretty"
```

---

## TP Bonus — Simuler une panne de nœud

### Objectif

Observer comment le cluster gère automatiquement la panne d'un nœud et récupère sa disponibilité.

### 8.1 Vérifier l'état initial

```bash
curl -X GET "http://localhost:9200/_cluster/health?pretty"
curl -X GET "http://localhost:9200/_cat/nodes?v&pretty"
```

Notez le nœud cluster manager (symbole `*`).

### 8.2 Arrêter un nœud non-master

```bash
# Arrêter le nœud 3 (data node)
docker stop opensearch-node3
```

### 8.3 Observer la récupération

```bash
# Suivre l'état du cluster en temps réel (toutes les 2 secondes)
watch -n 2 'curl -s http://localhost:9200/_cluster/health | python3 -m json.tool'
```

Observations attendues :
1. Immédiatement après l'arrêt : `status: yellow`, `unassigned_shards > 0`
2. Après ~30-60s : les shards se redistribuent vers les nœuds restants
3. `status` repasse à `green` quand tous les shards sont réassignés

### 8.4 Simuler la panne du nœud master

```bash
# Relancer node3 d'abord
docker start opensearch-node3

# Attendre que le cluster soit green, puis stopper node1 (cluster manager initial)
docker stop opensearch-node1
```

Observations :
1. Election d'un nouveau cluster manager parmi les nœuds restants
2. Le cluster reste disponible pendant l'élection
3. Vérifier avec `_cat/nodes` quel nœud est devenu le nouveau cluster manager

### 8.5 Restaurer le cluster complet

```bash
docker start opensearch-node1
# Attendre que tous les nœuds rejoignent le cluster
curl -X GET "http://localhost:9200/_cluster/health?wait_for_status=green&timeout=60s&pretty"
```

---

## Vérification finale

A la fin de ce TP, vous devez avoir :

- [ ] Cluster 3 nœuds démarré avec statut `green`
- [ ] Distribution des shards vérifiée avec `_cat/shards` et `_cat/allocation`
- [ ] Index template `products-template` créé et testé
- [ ] Alias `products-current` créé avec basculement v1 → v2 réalisé
- [ ] Snapshot créé dans le repository `backup-repo`
- [ ] Politique ISM `products-lifecycle` créée (hot → warm → delete)
- [ ] Monitoring des nœuds avec `_nodes/stats` et `_cat/nodes`
- [ ] (Bonus) Simulation de panne et observation de la récupération automatique

---

## Ressources

- [Documentation Cluster OpenSearch](https://opensearch.org/docs/latest/opensearch/cluster/)
- [Index Templates](https://opensearch.org/docs/latest/im-plugin/index-templates/)
- [Aliases](https://opensearch.org/docs/latest/opensearch/index-alias/)
- [Snapshot & Restore](https://opensearch.org/docs/latest/opensearch/snapshots/index/)
- [ISM (Index State Management)](https://opensearch.org/docs/latest/im-plugin/ism/index/)
