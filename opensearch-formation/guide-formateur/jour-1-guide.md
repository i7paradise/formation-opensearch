# Jour 1 — Guide formateur

## Timing global

| Heure | Durée | Activité | Type |
|-------|-------|----------|------|
| 09:00–09:30 | 30 min | Accueil, présentation, tour de table | Q/A |
| 09:30–09:45 | 15 min | Démo live ice breaker | Démo live |
| 09:45–10:20 | 35 min | Chapitre 1 : Introduction à OpenSearch | Cours |
| 10:20–10:30 | 10 min | Chapitre 2 : Installation — Docker Compose uniquement | Cours |
| 10:30–11:15 | 45 min | TP1 : Installation en local | TP |
| 11:15–11:30 | 15 min | Pause | Pause |
| 11:30–12:00 | 30 min | Chapitre 3a : Mappings & types de champs | Cours |
| 12:00–12:30 | 30 min | TP2 : Créer un index complet (nouveau) | TP |
| 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| 13:30–14:15 | 45 min | Chapitre 3b : API REST, CRUD, Bulk API & bonnes pratiques + antipatterns | Cours |
| 14:15–15:00 | 45 min | TP3 : CRUD, Bulk API & bonnes pratiques | TP |
| 15:00–15:15 | 15 min | Pause | Pause |
| 15:15–15:45 | 30 min | Chapitre 3c : Query DSL, match/term/range/bool (sans agrégations) | Cours |
| 15:45–16:30 | 45 min | TP4 : Requêtes & Recherche (sans agrégations) | TP |
| 16:30–17:00 | 30 min | Récap Jour 1, Q&A, preview Jour 2 | Q/A |

---

## Accueil + tour de table (09:00 — 30 min)

**Timing** : 30 min

**Ce que tu dis** :
> "Bonjour à tous, bienvenue dans cette formation OpenSearch 3.6. Trois jours ensemble pour explorer ce moteur de recherche de fond en comble — de l'installation jusqu'à la sécurisation d'un cluster en production. Mon objectif, c'est que vous repartiez d'ici avec assez de pratique pour être autonomes dans votre quotidien. On va beaucoup manipuler, peu lire des slides, et le fil rouge de la formation c'est la construction progressive d'un moteur de recherche e-commerce. Je voudrais que chacun se présente en 2-3 minutes : votre prénom, votre rôle, votre expérience avec les moteurs de recherche, et ce que vous espérez emporter de ces trois jours."

**Points clés** :
- Écouter et noter les profils (dev, ops, data, chef de projet)
- Identifier les niveaux : débutant / déjà utilisé ES / connaît OS
- Rappeler les horaires : 9h–17h, pauses à 11h15, 15h00 et déjeuner 12h30–13h30
- Indiquer où se trouve le support, les labs

**Questions fréquentes** :
- Q: "OpenSearch est-il compatible avec Elasticsearch ?" → R: "Très bonne question, démo dans 15 minutes."
- Q: "On utilise quel OS ?" → R: "Docker, donc ça marche pareil sur Mac, Linux et Windows."

**Transition** :
> "Parfait. Maintenant je vais vous montrer quelque chose qui va peut-être vous surprendre avant même qu'on parle de cours."

---

## Démo live ice breaker (09:30 — 15 min)

**Timing** : 15 min

**Ce que tu dis** :
> "Je vais lancer une requête contre un cluster OpenSearch et on va voir ce que ça donne. Pas besoin de comprendre chaque mot maintenant, c'est juste pour mettre les mains dedans tout de suite."

**Demo — séquence exacte** :

```bash
# 1. Vérifier que Docker tourne
docker compose -f infrastructure/docker-compose.yml up -d

# 2. Tester la réponse
curl -s http://localhost:9200/ | python3 -m json.tool

# 3. Indexer un document
curl -s -X PUT "http://localhost:9200/demo/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{"titre": "Formation OpenSearch", "niveau": "débutant", "année": 2026}' | python3 -m json.tool

# 4. Rechercher en plein texte
curl -s -X GET "http://localhost:9200/demo/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query": {"match": {"titre": "formation"}}}' | python3 -m json.tool
```

**Points clés** :
- OpenSearch répond toujours en JSON
- La recherche full-text marche immédiatement sans configuration
- Le `_score` montre la pertinence calculée

**Transition** :
> "Voilà ce qu'on va apprendre à faire — et beaucoup plus. Passons maintenant aux fondamentaux."

---

## Chapitre 1 — Introduction à OpenSearch (09:45 — 35 min)

**Timing** : 35 min

**Ce que tu dis** :
> "OpenSearch est né en 2021 quand Elastic a changé sa licence. AWS a forké Elasticsearch 7.10 et a créé OpenSearch — open source sous licence Apache 2.0. La communauté a suivi. Aujourd'hui, OpenSearch 3.6 a ses propres fonctionnalités qui n'existent pas dans Elasticsearch."

**Points clés** :
- Cas d'usage : e-commerce (notre fil rouge), logs (ELK/OpenSearch), analytics, recherche documentaire
- Architecture de base : Cluster → Nœuds → Index → Shards → Documents
- Comparaison SQL : Index ≈ Table, Document ≈ Ligne, Champ ≈ Colonne
- Différences clés vs SQL : schéma flexible, recherche full-text native, distribution horizontale

**Questions fréquentes** :
- Q: "C'est quoi Lucene ?" → R: "Le moteur sous-jacent, écrit en Java. OpenSearch est une couche distribuée par-dessus Lucene. On verra les internals Lucene en détail Jour 2."
- Q: "C'est mieux qu'Elasticsearch ?" → R: "Différent. OpenSearch est 100% open source, ES a des fonctionnalités propriétaires payantes. Pour la plupart des cas d'usage, les deux font l'affaire."

**Transition** :
> "Maintenant qu'on sait pourquoi ça existe, voyons comment l'installer — et c'est très rapide avec Docker."

---

## Chapitre 2 — Installation (10:20 — 10 min)

**Timing** : 10 min (bref, le TP fera le travail)

**Ce que tu dis** :
> "On va rester très pratique. En production on déploierait sur des VMs ou Kubernetes. Pour la formation, Docker Compose suffit et prend 2 minutes."

**Points clés** :
- `vm.max_map_count=262144` : obligatoire sur Linux (Lucene a besoin de nombreuses memory maps)
- `docker compose up -d` : tout démarre en arrière-plan
- `GET /_cluster/health` : votre première vérification après tout démarrage OpenSearch
- Mémoire JVM : `-Xms` = `-Xmx` = 50% de la RAM disponible (règle absolue)

**Transition** :
> "On fait tout ça dans le TP1 maintenant. Ouvrez votre terminal."

---

## TP1 — Installation en local (10:30 — 45 min)

**Ce que tu fais** :
- Circuler dans la salle, vérifier que chaque poste a Docker opérationnel
- Aider les participants bloqués sur `vm.max_map_count` sur Linux
- Signaler à 11h05 : "Encore 10 minutes, vérifiez que votre cluster répond en vert"

**Problèmes fréquents** :
- Port 9200 déjà utilisé → `docker ps` pour trouver le coupable
- `vm.max_map_count` pas appliqué → `sudo sysctl -w vm.max_map_count=262144`
- Docker pas assez de mémoire → augmenter dans Docker Desktop Preferences

---

## Pause (11:15 — 15 min)

---

## Chapitre 3a — Mappings & types de champs (11:30 — 30 min)

**Timing** : 30 min

**Ce que tu dis** :
> "Le mapping, c'est le schéma de votre index. La différence avec SQL : vous pouvez ne pas en définir un, et OpenSearch en créera un automatiquement. Mais en production, vous voulez toujours un mapping explicite."

**Points clés** :
- `text` : analysé pour la recherche full-text. Jamais pour les filtres ou agrégations.
- `keyword` : valeur exacte, non analysée. Pour les filtres, tris et agrégations.
- Multi-fields : `name` (text) + `name.keyword` (keyword) — pattern très courant
- `dynamic: strict` : rejette tout champ non mappé → protège contre les mapping explosions
- Types à connaître : `float`, `integer`, `boolean`, `date`, `geo_point`, `nested`

**Anecdote** :
> "En production, j'ai vu un index avec dynamic mapping qui s'est retrouvé avec 50 000 champs différents. OpenSearch OOM au bout d'une semaine. `dynamic: strict` aurait évité ça immédiatement."

**Questions fréquentes** :
- Q: "Peut-on modifier un mapping existant ?" → R: "Non pour les types. Oui pour ajouter des champs. Pour vraiment changer, on reindex (TP11)."
- Q: "C'est quoi le mapping dynamique ?" → R: "OpenSearch devine le type à partir de la première valeur reçue. Pratique en dev, dangereux en prod."

**Transition** :
> "Maintenant on va créer nous-mêmes un index avec tous ces types. TP2."

---

## TP2 — Créer un index complet (12:00 — 30 min)

**Ce que tu fais** :
- Ce TP est court et dense. Circuler activement.
- Pointer sur `_analyze` : "Regardez la différence entre text et keyword. C'est fondamental."
- À 12h25 : s'assurer que tout le monde a vu l'erreur `strict_dynamic_mapping_exception`

**Points à vérifier** :
- Tout le monde a créé l'index avec succès
- Tout le monde a observé la différence text/keyword dans `_analyze`
- Tout le monde a vu l'erreur `strict_dynamic_mapping_exception`

---

## Déjeuner (12:30 — 60 min)

---

## Chapitre 3b — API REST, CRUD, Bulk API & bonnes pratiques (13:30 — 45 min)

**Timing** : 45 min

**Ce que tu dis** :
> "OpenSearch expose une API REST. Chaque opération correspond à un verbe HTTP et une URL. C'est simple, prévisible, et vous pouvez tout faire avec curl."

**Points clés — CRUD** :
- `PUT /index/_doc/id` : créer ou remplacer (avec ID)
- `POST /index/_doc` : créer avec ID auto-généré
- `POST /index/_update/id` : mise à jour partielle (merge)
- `DELETE /index/_doc/id` : supprimer (marque comme tombstone, espace libéré au merge)

**Points clés — Bulk API** :
- Format NDJSON : ligne action + ligne document, pas de virgule
- `--data-binary` obligatoire (préserve les `\n`)
- Réponse : `errors: true/false` + tableau `items`

**Antipatterns à présenter** :
- Wildcard en début de terme (`*phone`) : scan complet → interdit en production
- Suppression individuelle à grande échelle : utiliser `_delete_by_query`
- Pas de `_source` filtering : retourner tous les champs même si inutile

**Bonnes pratiques** :
- `refresh_interval: -1` + `replicas: 0` pendant le chargement massif → 5-10x plus rapide
- `_source` filtering : ne retourner que les champs nécessaires
- Toujours Bulk API pour > 100 documents

**Questions fréquentes** :
- Q: "Quelle est la taille idéale d'un batch bulk ?" → R: "Entre 5 et 15 MB par requête. Trop grand = timeout. Trop petit = overhead HTTP."
- Q: "Le refresh automatique peut-on le désactiver définitivement ?" → R: "Oui, mais les données seront invisibles jusqu'au refresh manuel. En production, `1s` est le standard."

**Transition** :
> "On passe au TP3 — vous allez charger plus de 1000 produits en quelques secondes avec le Bulk API."

---

## TP3 — CRUD, Bulk API & bonnes pratiques (14:15 — 45 min)

**Ce que tu fais** :
- S'assurer que l'index `products` est créé avec le bon mapping
- À 14h50 : vérifier que tout le monde a `docs.count > 1000` dans `_cat/indices`
- Pointer l'Exercice 5 (antipatterns) : "Testez l'antipattern wildcard et observez le warning"

---

## Pause (15:00 — 15 min)

---

## Chapitre 3c — Query DSL (15:15 — 30 min)

**Timing** : 30 min — sans agrégations (déplacées au Jour 3)

**Ce que tu dis** :
> "Maintenant que les données sont là, les utilisateurs ont besoin de les trouver. OpenSearch utilise un langage de requêtes JSON appelé Query DSL. Deux contextes : query (avec score) et filter (sans score, cacheable)."

**Points clés** :
- Contexte query : `match`, `multi_match` — calcule un score BM25
- Contexte filter : `term`, `terms`, `range` — booléen, pas de score, mis en cache
- Bool query : `must` (score + obligatoire), `filter` (pas de score + cache), `should` (boost), `must_not`
- Règle d'or : si c'est oui/non → `filter`. Si c'est "à quel point ?" → `must`/`should`
- BM25 : TF (fréquence terme), IDF (rareté terme), longueur du champ → `_explain` pour déboguer

**Questions fréquentes** :
- Q: "On peut combiner match et filter ?" → R: "Oui, c'est le pattern le plus courant en production : must pour la recherche textuelle, filter pour les contraintes business."
- Q: "Les agrégations c'est quand ?" → R: "Demain matin Jour 3 — un chapitre entier + 75 min de TP dédié."

**Transition** :
> "On finit la journée avec le TP4 — implémenter une vraie barre de recherche e-commerce."

---

## TP4 — Requêtes & Recherche (15:45 — 45 min)

**Ce que tu fais** :
- S'assurer que l'index `products` a bien les données (sinon TP3 à finir)
- Circuler et aider sur la syntaxe JSON des bool queries
- Pointer `_explain` : "Regardez la décomposition BM25 — c'est ce que vous verrez dans le quiz demain"

**Points à vérifier** :
- Chaque participant a au moins testé : `match`, `filter`, `bool`, `_explain`

---

## Récap Jour 1 + Q&A + preview Jour 2 (16:30 — 30 min)

**Ce que tu dis** :
> "Récapitulons ce qu'on a fait aujourd'hui. On a installé OpenSearch, créé des mappings avec tous les types, chargé 1000+ produits avec le Bulk API, et implémenté des recherches avec le Query DSL. Demain on sécurise tout ça et on monte un vrai cluster multi-nœuds."

**Questions orales de vérification** :
1. "Quelle est la différence entre `text` et `keyword` ?"
2. "Pourquoi `dynamic: strict` en production ?"
3. "Quelle est la différence entre `must` et `filter` dans un bool query ?"
4. "Quels sont les 3 facteurs du score BM25 ?"
5. "Pour charger 50 000 produits, vous utilisez quoi ?"

**Preview Jour 2** :
> "Demain matin on commence par la sécurité — RBAC, utilisateurs, masquage de champs. Puis les fonctionnalités avancées : pipelines d'enrichissement et analyseurs français. L'après-midi, on monte un vrai cluster 3 nœuds et on observe le routing en action."
