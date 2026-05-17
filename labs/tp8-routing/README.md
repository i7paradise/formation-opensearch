# TP8 — Routage : démonstration de l'importance de l'algorithme

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 45 minutes                                           |
| Difficulté | Intermédiaire                                        |
| Prérequis  | TP7 terminé — cluster 3 nœuds en cours d'exécution   |
| Objectif   | Comprendre l'algorithme de routing et son impact sur la distribution des données |

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
  curl -s -X POST "https://localhost:9200/routing-demo-auto/_doc" \
    -k -u admin:admin \
    -H 'Content-Type: application/json' \
    -d "{\"id\": $i, \"category\": \"$CATEGORY\", \"value\": $RANDOM}" > /dev/null
done
echo "300 documents indexés"
```

> Note : Pour aller plus vite, utilisez le script `exercices.sh` qui fait un bulk.

### 1.3 Observer la distribution des shards

```bash
curl -s "https://localhost:9200/_cat/shards/routing-demo-auto?v&h=index,shard,prirep,docs,store,node" \
  -k -u admin:admin
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
CATEGORIES=("Électronique" "Électronique" "Électronique" "Vêtements" "Livres")
for i in $(seq 1 300); do
  CAT="${CATEGORIES[$((i % 5))]}"
  curl -s -X POST "https://localhost:9200/routing-demo-forced/_doc?routing=$CAT" \
    -k -u admin:admin \
    -H 'Content-Type: application/json' \
    -d "{\"id\": $i, \"category\": \"$CAT\", \"value\": $RANDOM}" > /dev/null
done
echo "300 documents indexés avec routing forcé"
```

### 2.3 Observer la distribution inégale

```bash
curl -s "https://localhost:9200/_cat/shards/routing-demo-forced?v&h=index,shard,prirep,docs,store,node" \
  -k -u admin:admin
```

**Observation** : Certains shards contiennent beaucoup plus de documents que d'autres (shard "chaud" sur Électronique). C'est un **hotspot**.

---

## Exercice 3 — Requête avec et sans routing

### 3.1 Sans routing (tous les shards interrogés)

```bash
time curl -s -X GET "https://localhost:9200/routing-demo-forced/_search?explain=false" \
  -k -u admin:admin \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "term": { "category": "Électronique" } }, "size": 5 }' \
  | jq -r '"Total: \(.hits.total.value) | Shards interrogés: \(._shards.total)"' 2>/dev/null
```

### 3.2 Avec routing (shard ciblé uniquement)

```bash
time curl -s -X GET "https://localhost:9200/routing-demo-forced/_search?routing=Électronique" \
  -k -u admin:admin \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "term": { "category": "Électronique" } }, "size": 5 }' \
  | jq -r '"Total: \(.hits.total.value) | Shards interrogés: \(._shards.total)"' 2>/dev/null
```

**Observation** : Avec `?routing=Électronique`, seul 1 shard est interrogé au lieu de 3. Les résultats sont identiques mais la requête est plus ciblée.

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

*Passez au [TP9 — Agrégations avancées](../tp9-agregations/README.md)*
