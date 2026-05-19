# TP10 — Routage : démonstration de l'importance de l'algorithme

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 45 minutes                                           |
| Difficulté | Intermédiaire                                        |
| Prérequis  | TP7 terminé — cluster 3 nœuds en cours d'exécution   |
| Objectif   | Comprendre l'algorithme de routing et son impact sur la distribution des données |

> **Stack utilisée** : `docker-compose.cluster.yml` (cluster 3 nœuds, sans sécurité)
> ```bash
> docker compose -f infrastructure/docker-compose.cluster.yml up -d
> ```
> OpenSearch est accessible sur `http://localhost:9200` sans authentification.

## Objectif

Montrer concrètement comment le routing impacte la distribution des données et les performances de recherche. Comprendre quand et comment utiliser le routing personnalisé.

## Contexte

Sur notre cluster 3 nœuds, les 1000+ produits doivent être distribués équitablement entre les shards. Mais que se passe-t-il si on utilise le routing forcé ? Ce TP révèle les effets concrets de l'algorithme `hash(_id) % nb_shards`.

---

## Exercice 1 — Distribution naturelle (ID automatique)

### 1.1 Créer un index avec 3 shards

```
PUT /routing-demo-auto
{
  "settings": { "number_of_shards": 3, "number_of_replicas": 1 }
}
```

### 1.2 Indexer 300 documents avec ID automatique

```bash
for i in $(seq 1 300); do
  CATEGORY="cat$((RANDOM % 5 + 1))"
  curl -s -X POST "http://localhost:9200/routing-demo-auto/_doc" \
    -H 'Content-Type: application/json' \
    -d "{\"id\": $i, \"category\": \"$CATEGORY\", \"value\": $RANDOM}" > /dev/null
done
echo "300 documents indexés"
```

> Note : Pour aller plus vite, utilisez le script `exercices.sh` qui fait un bulk.

### 1.3 Observer la distribution des shards

```bash
curl -s "http://localhost:9200/_cat/shards/routing-demo-auto?v&h=index,shard,prirep,docs,store,node"
```

**Observation attendue** : ~100 documents par shard primaire — distribution équitable grâce à l'algorithme de hash sur l'ID auto-généré.

---

## Exercice 2 — Routing forcé par catégorie

### 2.1 Créer un index avec routing forcé

```
PUT /routing-demo-forced
{
  "settings": { "number_of_shards": 3, "number_of_replicas": 1 }
}
```

### 2.2 Indexer des documents avec routing par catégorie

```bash
CATEGORIES=("electronique" "electronique" "electronique" "vetements" "livres")
for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((i % 5))]}"
  curl -s -X POST "http://localhost:9200/routing-demo-forced/_doc?routing=$CAT" \
    -H 'Content-Type: application/json' \
    -d "{\"id\": $i, \"category\": \"$CAT\", \"value\": $RANDOM}" > /dev/null
done
echo "300 documents indexés avec routing forcé"
```

> **Pourquoi des clés ASCII ?** Les caractères UTF-8 non encodés dans une URL (`?routing=Électronique`) peuvent être envoyés de manière inconsistante par curl, ce qui produit des hash différents pour le même routing key et disperse les docs sur plusieurs shards. Les clés ASCII simples garantissent un comportement déterministe.

### 2.3 Observer la distribution inégale

```bash
curl -s -X POST "http://localhost:9200/routing-demo-forced/_refresh"
curl -s "http://localhost:9200/_cat/shards/routing-demo-forced?v&h=index,shard,prirep,docs,store,node"
```

> Le `_refresh` est nécessaire avant de lire les stats : `_cat/shards` affiche les comptes Lucene des segments committés, pas ceux en mémoire. Sans refresh, un primary peut afficher 0 doc alors que sa replica en montre déjà 80.

**Observation** : Certains shards contiennent beaucoup plus de documents que d'autres (shard "chaud" sur `electronique`). C'est un **hotspot**.

---

## Exercice 3 — Requête avec et sans routing

### 3.1 Sans routing (tous les shards interrogés)

```bash
time curl -s -X GET "http://localhost:9200/routing-demo-forced/_search?explain=false" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "term": { "category": "electronique" } }, "size": 5 }' \
  | jq -r '"Total: \(.hits.total.value) | Shards interrogés: \(._shards.total)"'
```

### 3.2 Avec routing (shard ciblé uniquement)

```bash
time curl -s -X GET "http://localhost:9200/routing-demo-forced/_search?routing=electronique" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "term": { "category": "electronique" } }, "size": 5 }' \
  | jq -r '"Total: \(.hits.total.value) | Shards interrogés: \(._shards.total)"'
```

**Observation** : Avec `?routing=electronique`, seul 1 shard est interrogé au lieu de 3. Les résultats sont identiques mais la requête est plus ciblée.

---

## Exercice 4 — Simuler un shard chaud

```
GET /routing-demo-forced/_search
{
  "size": 0,
  "aggs": {
    "par_categorie": {
      "terms": { "field": "category", "size": 10 }
    }
  }
}
```

> **Impact en production** : Un shard qui reçoit 60% des requêtes devient un goulot d'étranglement. Le nœud qui héberge ce shard est surchargé pendant que les autres sont sous-utilisés.

---

## TP Bonus — Diagnostiquer un shard non assigné

```
GET /_cluster/allocation/explain
{
  "index": "routing-demo-forced",
  "shard": 0,
  "primary": true
}
```

---

## Vérification finale

- [ ] Index `routing-demo-auto` : distribution équitable ~100 docs/shard
- [ ] Index `routing-demo-forced` : distribution inégale — hotspot visible
- [ ] Requête sans routing : tous les shards interrogés
- [ ] Requête avec routing : 1 seul shard interrogé
- [ ] Comprendre pourquoi le routing forcé peut être un avantage (ciblage) ou un risque (hotspot)

*Passez au [TP11 — Agrégations avancées](../tp11-agregations/README.md)*
