# TP7 — Installation cluster 3 nœuds

## Informations générales

| Paramètre  | Valeur                                      |
|------------|---------------------------------------------|
| Durée      | 45 minutes                                  |
| Difficulté | Avancé                                      |
| Prérequis  | TP6 terminé                                 |
| Objectif   | Démarrer un cluster 3 nœuds et vérifier la distribution des shards |

## Objectif

Configurer et démarrer un cluster OpenSearch 3 nœuds, puis vérifier son bon fonctionnement et la distribution des shards.

> **Note** : ISM et Snapshots → TP12

## Contexte

Notre moteur de recherche e-commerce est actuellement sur un nœud unique — une configuration inacceptable pour la production. Vous allez migrer vers une architecture haute disponibilité avec 3 nœuds.

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

## Exercice 3 — Monitorer le cluster

### 3.1 Statistiques des nœuds

```bash
# Vue synthétique des nœuds
curl -X GET "http://localhost:9200/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu,load_1m,master,node.role&pretty"
```

### 3.2 Statistiques du cluster

```bash
curl -X GET "http://localhost:9200/_cluster/stats?pretty"
```

### 3.3 Vérifier les tâches en cours

```bash
curl -X GET "http://localhost:9200/_tasks?actions=*search*&pretty"
```

---

## TP Bonus — Simuler une panne de nœud

### Objectif

Observer comment le cluster gère automatiquement la panne d'un nœud et récupère sa disponibilité.

### Étape 1 : Vérifier l'état initial

```bash
curl -X GET "http://localhost:9200/_cluster/health?pretty"
curl -X GET "http://localhost:9200/_cat/nodes?v&pretty"
```

Notez le nœud cluster manager (symbole `*`).

### Étape 2 : Arrêter un nœud non-master

```bash
# Arrêter le nœud 3 (data node)
docker stop opensearch-node3
```

### Étape 3 : Observer la récupération

```bash
# Suivre l'état du cluster en temps réel (toutes les 2 secondes)
watch -n 2 'curl -s http://localhost:9200/_cluster/health?pretty'
```

Observations attendues :
1. Immédiatement après l'arrêt : `status: yellow`, `unassigned_shards > 0`
2. Après ~30-60s : les shards se redistribuent vers les nœuds restants
3. `status` repasse à `green` quand tous les shards sont réassignés

### Étape 4 : Restaurer le cluster complet

```bash
docker start opensearch-node3
# Attendre que tous les nœuds rejoignent le cluster
curl -X GET "http://localhost:9200/_cluster/health?wait_for_status=green&timeout=60s&pretty"
```

---

## Vérification finale

- [ ] Cluster 3 nœuds démarré avec statut `green`
- [ ] Distribution des shards vérifiée avec `_cat/shards` et `_cat/allocation`
- [ ] Les 3 nœuds visibles dans `_cat/nodes`
- [ ] Monitoring des nœuds avec `_cat/nodes`
- [ ] (Bonus) Simulation de panne et observation de la récupération automatique

---

## Ressources

- [Documentation Cluster OpenSearch](https://opensearch.org/docs/latest/opensearch/cluster/)
- [Snapshot & Restore → voir TP12](../tp13-reindex-ism/README.md)
- [ISM (Index State Management) → voir TP12](../tp13-reindex-ism/README.md)

*Passez au [TP9 — Reindex & Resharding](../tp9-reindex/README.md)*
