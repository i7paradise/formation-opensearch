# TP6 — Solution complète : Cluster multi-nœuds

## Exercice 1 — Démarrage du cluster

### Commandes complètes

```bash
# Arrêter l'environnement mono-nœud
docker compose -f infrastructure/docker-compose.yml down

# Démarrer le cluster 3 nœuds
docker compose -f infrastructure/docker-compose.cluster.yml up -d

# Vérifier que les 3 containers sont démarrés
docker compose -f infrastructure/docker-compose.cluster.yml ps
```

**Résultat attendu `docker ps` :**
```
NAME                STATUS          PORTS
opensearch-node1    Up 2 minutes    0.0.0.0:9200->9200/tcp
opensearch-node2    Up 2 minutes    0.0.0.0:9201->9200/tcp
opensearch-node3    Up 2 minutes    0.0.0.0:9202->9200/tcp
opensearch-dashboards Up 2 minutes  0.0.0.0:5601->5601/tcp
```

### Vérification de l'état du cluster

```bash
curl -X GET "http://localhost:9200/_cluster/health?pretty"
```

```json
{
  "cluster_name" : "opensearch-cluster",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "discovered_master" : true,
  "discovered_cluster_manager" : true,
  "active_primary_shards" : 15,
  "active_shards" : 30,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

---

## Exercice 2 — Distribution des shards

### Commandes et interprétation

```bash
curl -X GET "http://localhost:9200/_cat/shards?v&pretty"
```

**Exemple de sortie :**
```
index          shard prirep state   docs  store ip           node
products       0     p      STARTED  342   2mb  172.18.0.2   opensearch-node1
products       0     r      STARTED  342   2mb  172.18.0.3   opensearch-node2
products       1     p      STARTED  341   2mb  172.18.0.3   opensearch-node2
products       1     r      STARTED  341   2mb  172.18.0.4   opensearch-node3
products       2     p      STARTED  339   2mb  172.18.0.4   opensearch-node3
products       2     r      STARTED  339   2mb  172.18.0.2   opensearch-node1
```

**Règle d'or :** Un shard primaire et sa réplique ne sont JAMAIS sur le même nœud. OpenSearch garantit cela automatiquement.

```bash
curl -X GET "http://localhost:9200/_cat/allocation?v&pretty"
```

**Exemple de sortie :**
```
shards disk.indices disk.used disk.avail disk.total disk.percent host         ip           node
10     45mb         12.3gb    87.7gb     100gb      12           172.18.0.2   172.18.0.2   opensearch-node1
10     45mb         12.3gb    87.7gb     100gb      12           172.18.0.3   172.18.0.3   opensearch-node2
10     45mb         12.3gb    87.7gb     100gb      12           172.18.0.4   172.18.0.4   opensearch-node3
```

**Interprétation :** Chaque nœud héberge exactement 10 shards (répartition équilibrée).

---

## Exercice 3 — Index Template

### Création des composants

```bash
# Composant mapping
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

**Réponse attendue :** `{"acknowledged":true}`

```bash
# Composant settings
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

```bash
# Template composite
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

### Vérification du template

```bash
# Lister tous les templates
curl -X GET "http://localhost:9200/_index_template?pretty"

# Détail du template
curl -X GET "http://localhost:9200/_index_template/products-template?pretty"

# Tester avec un nouvel index
curl -X PUT "http://localhost:9200/products-2026-01" -H "Content-Type: application/json" -d '{}'
curl -X GET "http://localhost:9200/products-2026-01/_mapping?pretty"
curl -X GET "http://localhost:9200/products-2026-01/_alias?pretty"
```

**Résultat :** Le mapping est automatiquement appliqué sans avoir besoin de le définir à la création de l'index.

---

## Exercice 4 — Aliases

### Séquence complète de basculement sans interruption

```bash
# Étape 1 : Créer products-v1 et indexer des données
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

```bash
# Étape 2 : Créer l'alias pointant sur v1
curl -X POST "http://localhost:9200/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      {
        "add": {
          "index":          "products-v1",
          "alias":          "products-current",
          "is_write_index": true
        }
      }
    ]
  }'
```

```bash
# Étape 3 : Les clients utilisent "products-current" (transparent)
curl -X GET "http://localhost:9200/products-current/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} } }'
```

```bash
# Étape 4 : Créer products-v2 avec un champ supplémentaire
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
```

```bash
# Étape 5 : Réindexer les données
curl -X POST "http://localhost:9200/_reindex" \
  -H "Content-Type: application/json" \
  -d '{
    "source": { "index": "products-v1" },
    "dest":   { "index": "products-v2" }
  }'
```

```bash
# Étape 6 : Basculement ATOMIQUE (zéro downtime)
curl -X POST "http://localhost:9200/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      { "remove": { "index": "products-v1", "alias": "products-current" } },
      { "add":    { "index": "products-v2", "alias": "products-current", "is_write_index": true } }
    ]
  }'
```

```bash
# Vérification : les clients obtiennent maintenant les données v2
curl -X GET "http://localhost:9200/products-current/_count"
curl -X GET "http://localhost:9200/_cat/aliases?v&pretty"
```

**Résultat `_cat/aliases` :**
```
alias            index        filter routing.index routing.search is_write_index
products-current products-v2  -      -             -             true
products-all     products-v1  -      -             -             -
products-all     products-v2  -      -             -             -
```

---

## Exercice 5 — Snapshot

### Prérequis Docker

Le volume doit être configuré dans `docker-compose.cluster.yml` :
```yaml
volumes:
  - opensearch-snapshots:/mnt/snapshots
```

Et le paramètre dans opensearch.yml de chaque nœud :
```yaml
path.repo: ["/mnt/snapshots"]
```

### Commandes complètes

```bash
# Enregistrer le repository
curl -X PUT "http://localhost:9200/_snapshot/backup-repo" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/mnt/snapshots",
      "compress": true
    }
  }'

# Vérifier l'accès depuis les 3 nœuds
curl -X POST "http://localhost:9200/_snapshot/backup-repo/_verify?pretty"
```

**Réponse `_verify` :**
```json
{
  "nodes" : {
    "node-id-1" : { "name" : "opensearch-node1" },
    "node-id-2" : { "name" : "opensearch-node2" },
    "node-id-3" : { "name" : "opensearch-node3" }
  }
}
```

```bash
# Créer le snapshot
curl -X PUT "http://localhost:9200/_snapshot/backup-repo/snapshot-products-2026-01-15?wait_for_completion=true" \
  -H "Content-Type: application/json" \
  -d '{
    "indices":              "products-*",
    "ignore_unavailable":   true,
    "include_global_state": false,
    "metadata": {
      "taken_by":      "formation-tp6",
      "taken_because": "Sauvegarde avant migration v2"
    }
  }'
```

**Réponse :**
```json
{
  "snapshot": {
    "snapshot":  "snapshot-products-2026-01-15",
    "state":     "SUCCESS",
    "indices":   ["products-v1", "products-v2", "products-2026-01"],
    "shards":    { "total": 9, "failed": 0, "successful": 9 }
  }
}
```

---

## Exercice 6 — Politique ISM

### Logique de la politique

```
Création de l'index
       │
       ▼
   État: hot
   - Rollover si âge > 7j OU docs > 10k OU taille > 5gb
       │
       │ (après 7 jours)
       ▼
   État: warm
   - Réduction des réplicas à 0
   - Priorité de récupération abaissée à 50
       │
       │ (après 30 jours total)
       ▼
   État: delete
   - Suppression automatique de l'index
```

### Commandes

```bash
# Créer la politique
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
            { "replica_count":  { "number_of_replicas": 0 } },
            { "index_priority": { "priority": 50 } }
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
          "actions": [ { "delete": {} } ],
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

# Vérifier la politique
curl -X GET "http://localhost:9200/_plugins/_ism/policies/products-lifecycle?pretty"

# Attacher à un index existant
curl -X POST "http://localhost:9200/_plugins/_ism/add/products-2026-01" \
  -H "Content-Type: application/json" \
  -d '{ "policy_id": "products-lifecycle" }'

# Vérifier l'état ISM
curl -X GET "http://localhost:9200/_plugins/_ism/explain/products-2026-01?pretty"
```

---

## Exercice 7 — Monitoring

### Récapitulatif des commandes

```bash
# État du cluster
curl -s "http://localhost:9200/_cluster/health?pretty"

# Nœuds (vue synthétique)
curl -s "http://localhost:9200/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu,load_1m,master,node.role&pretty"

# Shards
curl -s "http://localhost:9200/_cat/shards?v&pretty"

# Allocation
curl -s "http://localhost:9200/_cat/allocation?v&pretty"

# Statistiques JVM et indices des nœuds
curl -s "http://localhost:9200/_nodes/stats/jvm,indices?pretty"

# Index stats
curl -s "http://localhost:9200/products/_stats?pretty"

# Tâches actives
curl -s "http://localhost:9200/_tasks?pretty"

# Pending cluster tasks
curl -s "http://localhost:9200/_cluster/pending_tasks?pretty"
```

### Seuils d'alerte recommandés

| Métrique                          | Avertissement | Critique |
|-----------------------------------|---------------|----------|
| `jvm.heap_used_percent`           | > 75%         | > 85%    |
| `os.cpu.percent`                  | > 70%         | > 90%    |
| `disk.percent` (`_cat/allocation`)| > 75%         | > 85%    |
| `active_shards_percent`           | < 95%         | < 90%    |
| `unassigned_shards`               | > 0           | > 5      |

---

## Bonus — Simulation de panne

### Séquence complète commentée

```bash
# État initial - tous les nœuds green
curl -s "http://localhost:9200/_cluster/health?pretty"

# Identifier le cluster manager
curl -s "http://localhost:9200/_cat/nodes?v&h=name,master&pretty"

# Stopper un data node (non-master)
docker stop opensearch-node3

# Observer immédiatement : status yellow, shards unassigned
curl -s "http://localhost:9200/_cluster/health?pretty"

# Après 30-60s : les shards se redistribuent
curl -s "http://localhost:9200/_cat/shards?v&pretty"

# Vérifier que les données sont toujours accessibles
curl -s "http://localhost:9200/products-current/_count"

# Redémarrer le nœud
docker start opensearch-node3

# Attendre le retour à green
curl -s "http://localhost:9200/_cluster/health?wait_for_status=green&timeout=60s&pretty"
```

**Points clés observés :**
1. **Tolérance aux pannes** : avec 1 réplique, le cluster survit à la perte d'1 nœud sur 3
2. **Récupération automatique** : les shards se redistribuent sans intervention manuelle
3. **Quorum** : avec `cluster.initial_cluster_manager_nodes: 3`, le cluster reste opérationnel avec 2 nœuds sur 3 (quorum = ceil(3/2)+1 = 2)
4. **Données accessibles** : malgré la panne, les recherches continuent de fonctionner

---

## Résumé des concepts clés

| Concept          | Rôle                                                                 |
|------------------|----------------------------------------------------------------------|
| Index Template   | Applique automatiquement mapping/settings aux nouveaux index         |
| Component Template | Bloc réutilisable de mapping ou settings (composé dans les templates) |
| Alias            | Nom logique pointant vers un ou plusieurs index physiques            |
| Snapshot         | Sauvegarde point-dans-le-temps d'un ou plusieurs index              |
| ISM Policy       | Automatise le cycle de vie des index (hot/warm/cold/delete)          |
| Quorum           | Nombre minimum de nœuds nécessaires pour élire un cluster manager   |
