# TP1 — Solution & Sorties Attendues

## Solution de l'Exercice 1 — Démarrer le cluster

### Commandes de démarrage

```bash
cd infrastructure/
docker compose up -d
```

**Sortie attendue :**
```
[+] Running 3/3
 ✔ Network infrastructure_opensearch-net        Created
 ✔ Container opensearch                         Started
 ✔ Container opensearch-dashboards              Started
```

```bash
docker compose ps
```

**Sortie attendue (après ~60s) :**
```
NAME                     IMAGE                                          COMMAND                  SERVICE                  CREATED          STATUS                    PORTS
opensearch               opensearchproject/opensearch:3.6.0             "./opensearch-docker…"   opensearch               2 minutes ago    Up 2 minutes (healthy)    0.0.0.0:9200->9200/tcp, 0.0.0.0:9600->9600/tcp
opensearch-dashboards    opensearchproject/opensearch-dashboards:3.6.0  "./opensearch-dashbo…"   opensearch-dashboards    2 minutes ago    Up 2 minutes (healthy)    0.0.0.0:5601->5601/tcp
```

---

## Solution de l'Exercice 2 — Vérifier la santé du cluster

### 2.1 Résultat de `GET _cluster/health`

```bash
curl -s http://localhost:9200/_cluster/health | python3 -m json.tool
```

**Sortie attendue :**
```json
{
    "cluster_name": "docker-cluster",
    "status": "green",
    "timed_out": false,
    "number_of_nodes": 1,
    "number_of_data_nodes": 1,
    "discovered_cluster_manager": true,
    "active_primary_shards": 4,
    "active_shards": 4,
    "relocating_shards": 0,
    "initializing_shards": 0,
    "unassigned_shards": 0,
    "delayed_unassigned_shards": 0,
    "number_of_pending_tasks": 0,
    "number_of_in_flight_fetch": 0,
    "task_max_waiting_in_queue_millis": 0,
    "active_shards_percent_as_number": 100.0
}
```

### 2.2 Résultat de `GET /`

```bash
curl -s http://localhost:9200/
```

**Sortie attendue :**
```json
{
  "name" : "opensearch",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "abc123xyz...",
  "version" : {
    "distribution" : "opensearch",
    "number" : "3.6.0",
    "build_type" : "tar",
    "build_hash" : "...",
    "build_date" : "...",
    "build_snapshot" : false,
    "lucene_version" : "9.x.x",
    "minimum_wire_compatibility_version" : "7.10.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}
```

### Réponses aux questions

- **Nom du cluster par défaut** : `docker-cluster` (défini dans docker-compose.yml)
- **Nombre de nœuds** : 1 (configuration single-node)
- **Rôle du nœud** : `cluster_manager`, `data`, `ingest`, `remote_cluster_client` (nœud tout-en-un)

---

## Solution de l'Exercice 3 — Cat APIs

### 3.1 `_cat/nodes?v`

```bash
curl -s "http://localhost:9200/_cat/nodes?v"
```

**Sortie attendue :**
```
ip         heap.percent ram.percent cpu load_1m load_5m load_15m node.role   master name
172.18.0.2           35          85   2    0.10    0.12     0.08 cdhimrst    *      opensearch
```

Colonnes importantes :
- `heap.percent` : utilisation du tas JVM (idéalement < 75%)
- `node.role` : `c`=cluster_manager, `d`=data, `h`=hot, `i`=ingest, `m`=master (eligible), `r`=remote, `s`=search, `t`=transform
- `master` : `*` indique le cluster manager actuel

### 3.2 `_cat/indices?v`

```bash
curl -s "http://localhost:9200/_cat/indices?v"
```

**Sortie attendue :**
```
health status index                        uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .opensearch-observability    abc123...              1   0          0            0       208b           208b
green  open   .plugins-ml-config           def456...              1   0          1            0      3.8kb          3.8kb
green  open   .ql-datasources              ghi789...              1   0          0            0       208b           208b
```

Indices système présents :
- `.opensearch-observability` : observabilité
- `.plugins-ml-config` : configuration du plugin Machine Learning
- `.ql-datasources` : sources de données SQL/PPL

### 3.3 `_cat/shards?v`

```bash
curl -s "http://localhost:9200/_cat/shards?v"
```

L'état `STARTED` signifie que le shard est **actif et opérationnel**, en train de servir des requêtes. Les autres états possibles sont :
- `INITIALIZING` : shard en cours d'initialisation (récupération de données)
- `RELOCATING` : shard en cours de déplacement vers un autre nœud
- `UNASSIGNED` : shard non assigné à un nœud (problème !)

### 3.4 Cat APIs disponibles

Exemples d'APIs Cat utiles pour le monitoring :
- `_cat/health` : état général du cluster
- `_cat/allocation` : allocation de shards par nœud
- `_cat/pending_tasks` : tâches en attente
- `_cat/recovery` : état des récupérations de shards
- `_cat/thread_pool` : état des pools de threads
- `_cat/segments` : segments Lucene des indices

---

## Solution de l'Exercice 4 — Dashboards

### Navigation dans Dev Tools

Requêtes à saisir dans la Dev Tools Console (http://localhost:5601) :

```
GET _cluster/health
```

```
GET _cat/nodes?v&format=json
```

```
GET _cat/indices?v&format=json
```

**Astuce** : Utilisez `Ctrl+Enter` pour exécuter une requête dans la Dev Tools Console.

### Stack Management > Index Management

Vous verrez les indices système listés avec :
- Leur santé (green/yellow/red)
- Leur nombre de documents
- Leur taille sur disque
- Leur nombre de shards primaires et réplicas

---

## Solution de l'Exercice 5 — Modifier la configuration

### 5.1 Modifier docker-compose.yml

Ajoutez dans la section `environment` du service `opensearch` :

```yaml
services:
  opensearch:
    environment:
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
      - DISABLE_SECURITY_PLUGIN=true
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=Formation@OpenSearch2024!
      - cluster.name=ecommerce-search    # <-- Ligne ajoutée
```

### 5.2 Vérification après redémarrage

```bash
curl -s http://localhost:9200/ | python3 -m json.tool
```

**Sortie attendue (extrait) :**
```json
{
  "name": "opensearch",
  "cluster_name": "ecommerce-search",
  ...
}
```

### 5.3 Modifier les paramètres dynamiques

**Désactiver l'auto-création d'index :**
```bash
curl -s -X PUT "http://localhost:9200/_cluster/settings" \
  -H 'Content-Type: application/json' \
  -d '{
    "persistent": {
      "action.auto_create_index": "false"
    }
  }'
```

**Remettre à la valeur par défaut :**
```bash
curl -s -X PUT "http://localhost:9200/_cluster/settings" \
  -H 'Content-Type: application/json' \
  -d '{
    "persistent": {
      "action.auto_create_index": null
    }
  }'
```

**Vérifier les paramètres actifs :**
```bash
curl -s "http://localhost:9200/_cluster/settings?include_defaults=true" | python3 -m json.tool | grep auto_create
```

---

## Points clés à retenir

1. **`_cluster/health`** est votre premier réflexe pour diagnostiquer l'état du cluster. Un statut `red` signifie que des shards primaires sont manquants — le cluster ne peut pas traiter toutes les requêtes.

2. **Les Cat APIs** (`_cat/*`) sont conçues pour être lues par des humains dans un terminal. Pour des outils automatisés, préférez les APIs JSON.

3. **single-node** : en développement, `discovery.type=single-node` empêche le cluster d'attendre d'autres nœuds pour former un quorum.

4. **La Dev Tools Console** de Dashboards est idéale pour développer et tester des requêtes OpenSearch avec autocomplétion.

5. **Paramètres persistants vs transitoires** :
   - `persistent` : survivent aux redémarrages du cluster
   - `transient` : perdus lors d'un redémarrage complet
   - `null` : remet à la valeur par défaut du fichier de configuration
