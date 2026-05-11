# Jour 2 — Guide formateur : Sécurité, Fonctionnalités avancées & Cluster

## Timing global

| Heure | Durée | Activité | Type |
|-------|-------|----------|------|
| 09:00 | 45 min | Chapitre 8 : Sécurité (RBAC, DLS, FLS) | Cours |
| 09:45 | 15 min | Pause | Pause |
| 10:00 | 30 min | TP5 : Sécurisation RBAC + FLS | TP |
| 10:30 | 60 min | Chapitre 4 : Fonctionnalités avancées | Cours |
| 11:30 | 60 min | TP6 : Pipelines & Analyseurs | TP |
| 12:30 | 60 min | Déjeuner | Déjeuner |
| 13:30 | 75 min | Chapitre 6 : Architecture & Cluster | Cours |
| 14:45 | 45 min | TP7 : Installation cluster 3 nœuds | TP |
| 15:30 | 15 min | Pause | Pause |
| 15:45 | 45 min | TP8 : Routage — démonstration (nouveau) | TP |
| 16:30 | 30 min | Récap Jour 2 + Q&A + preview Jour 3 | Q/A |

---

## Récap rapide Jour 1 (début de session — 5 min)

**Questions orales** :
1. "Différence entre text et keyword ?"
2. "Pourquoi `dynamic: strict` ?"
3. "Quelle est la différence entre `must` et `filter` dans un bool query ?"

---

## Chapitre 8 — Sécurité OpenSearch (09:00 — 45 min)

**Timing** : 45 min

**Ce que tu dis** :
> "Par défaut, OpenSearch en démo n'a pas de sécurité. En production, c'est inacceptable. Le Security Plugin est inclus gratuitement dans OpenSearch — c'est un avantage majeur par rapport à Elasticsearch où la sécurité est payante."

**Points clés** :
- Security Plugin overview : Authentication → Authorization → Audit Logging
- RBAC : Rôles → Permissions (cluster + index) → Mapping utilisateur/rôle
- DLS (Document Level Security) : filtre de requête automatique selon le rôle
- FLS (Field Level Security) : masquer des champs selon le rôle (préfixe `~`)
- Slide "pour aller plus loin" : TLS inter-nœuds et REST, LDAP, SAML — ce sera dans la documentation mais pas dans le TP d'aujourd'hui

**Démonstration live** :
```bash
# Se connecter en admin
curl -k -u admin:admin "https://localhost:9200/_plugins/_security/authinfo?pretty"

# Créer un rôle read-only
curl -k -u admin:admin -X PUT "https://localhost:9200/_plugins/_security/api/roles/demo_reader" \
  -H "Content-Type: application/json" \
  -d '{"index_permissions":[{"index_patterns":["products*"],"allowed_actions":["read"]}]}'
```

**Questions fréquentes** :
- Q: "TLS n'est pas dans le TP ?" → R: "TLS est important mais long à configurer. Le TP se concentre sur RBAC et FLS — les deux fonctionnalités les plus utilisées quotidiennement. TLS est mentionné en slide et dans les ressources."
- Q: "Le mot de passe admin par défaut `admin:admin` est dangereux ?" → R: "Absolument. En production : changer immédiatement. Pour la formation c'est commode."

**Transition** :
> "On va maintenant créer nos propres rôles et utilisateurs. TP5 — 30 minutes."

---

## TP5 — Sécurisation RBAC + FLS (10:00 — 30 min)

**Ce que tu fais** :
- Vérifier que tous les postes ont le cluster démarré avec sécurité activée
- S'assurer que chaque participant voit le 403 lors de l'écriture avec l'utilisateur `analyst`
- Point sur FLS : "Observez que le champ `price` a disparu de la réponse"

---

## Pause (09:45 — 15 min)

---

## Chapitre 4 — Fonctionnalités avancées (10:30 — 60 min)

**Timing** : 60 min

**Ce que tu dis** :
> "On a un moteur de recherche qui fonctionne. Maintenant on va le rendre intelligent : enrichissement automatique des données à l'indexation, meilleure recherche en français, et mise en valeur des termes dans les résultats."

### Ingest Pipelines (20 min)

**Points clés** :
- Pipeline = séquence de processeurs exécutée côté serveur à l'indexation
- Processeurs communs : `lowercase`, `trim`, `set`, `remove`, `grok` (logs), `date`
- `_simulate` : TOUJOURS tester avant d'appliquer en production
- Un seul pipeline peut servir tous les clients → centralisation de la logique

**Anecdote** :
> "En prod, j'ai vu un processeur `remove` appliqué sur le mauvais champ — 2 millions de documents sans `user_id`. La seule solution : reindexer depuis sauvegarde. `_simulate` aurait pris 30 secondes."

### Analyseurs et Tokenizers (20 min)

**Points clés** :
- Chaîne d'analyse : Char Filter → Tokenizer → Token Filters
- `standard` tokenizer : découpe par espace et ponctuation, tout en minuscules
- Token filters importants : `lowercase`, `asciifolding` (é→e), `stop`, `stemmer`
- Analyseur français : `lowercase` + `asciifolding` + `french_stop` + `french_stemmer`
- Toujours tester avec `_analyze`

### Surlignage, Tri et optimisation (20 min)

**Points clés** :
- `highlight` : clause au même niveau que `query`, retourne des extraits avec les termes surlignés
- Tris : sur les champs `keyword` ou numériques uniquement (`name.keyword` pas `name`)
- `search_after` vs `from+size` : pour la pagination profonde (> 10 000 résultats)
- Géolocalisation et completion suggester → TPs optionnels dédiés

**Transition** :
> "TP6 — vous allez créer un pipeline, un analyseur français et tester le highlighting."

---

## TP6 — Pipelines & Analyseurs (11:30 — 60 min)

**Ce que tu fais** :
- Circuler, aider sur la syntaxe des analyseurs dans les `settings`
- À 12h15 : "Même si vous n'avez pas fini, regardez la correction — on passe au déjeuner"

---

## Déjeuner (12:30 — 60 min)

---

## Chapitre 6 — Architecture & Cluster (13:30 — 75 min)

**Timing** : 75 min — chapitre dense, très important

**Ce que tu dis** :
> "On a fait des requêtes sur un seul nœud. En production, ça n'existe pas. Un seul nœud = point de défaillance unique. On va comprendre comment OpenSearch distribue les données et les requêtes."

### Internals Lucene (15 min)

**Points clés** :
- Lucene = index inversé : terme → liste de documents (posting list)
- Segments Lucene : immutables, les nouvelles données vont dans de nouveaux segments
- Merges : en arrière-plan, Lucene consolide les petits segments en gros
- Refresh (1s par défaut) : rend les nouveaux documents visibles (crée un nouveau segment en RAM)

### Types de nœuds (10 min)

**Points clés** :
- `master` / master-eligible : gère l'état du cluster (pas de données, coordonne)
- `data` : stocke et indexe les données, exécute les requêtes
- `ingest` : applique les pipelines avant indexation
- `coordinating` (implicite sur tous les nœuds) : route les requêtes vers les shards concernés
- En production avec > 5 nœuds : nœuds master dédiés (rôle `master` uniquement)

### Discovery et quorum (10 min)

**Points clés** :
- Quorum = ⌊N/2⌋ + 1 nœuds master-eligible pour élire un master
- 3 nœuds master-eligible → quorum = 2 → peut perdre 1 nœud
- `cluster.initial_master_nodes` : uniquement pour le bootstrap initial, à retirer ensuite
- Split-brain : situation où deux partitions du cluster pensent chacune être le master → quorum évite ça

### Sizing des shards (10 min)

**Points clés** :
- Règle d'or : 10–50 GB par shard
- Trop de shards = overhead de coordination
- Trop peu = shards qui ne tiennent pas en mémoire
- Nombre de shards primaires = fixe après création → bien estimer à l'avance

### Algorithme de routage (15 min) — point central de la journée

**Ce que tu dis** :
> "Quand vous indexez un document, OpenSearch doit décider dans quel shard il va. L'algorithme est déterministe : `hash(_id) % number_of_shards`. C'est pour ça qu'on ne peut pas changer le nombre de shards primaires : si on changeait N, tous les documents existants seraient introuvables."

**Points clés** :
- Routing par défaut : `hash(_id) % nb_shards`
- Routing personnalisé : `?routing=valeur` → force le shard cible
- Avantage routing custom : requête ne touche qu'1 shard au lieu de tous
- Risque routing custom : hotspot (1 shard reçoit tout le trafic)
- Demo : `_cat/shards` avant et après routing forcé

### Scalabilité (15 min)

**Points clés** :
- Ajouter des nœuds : les shards se redistribuent automatiquement (rebalancing)
- Ajouter des replicas : ne pas changer le nombre de primaires (reindex nécessaire)
- Anticiper la croissance : mieux vaut 5 shards trop nombreux que 1 trop peu

**Questions fréquentes** :
- Q: "Combien de nœuds minimum pour la production ?" → R: "3 nœuds minimum : 1 peut tomber et le cluster reste opérationnel avec quorum 2/3."
- Q: "Que se passe-t-il si le nœud master tombe ?" → R: "Élection automatique parmi les nœuds master-eligible, en moins de 30 secondes en général. On le verra dans le bonus du TP7."

**Transition** :
> "On va maintenant démarrer notre propre cluster 3 nœuds. TP7."

---

## TP7 — Installation cluster 3 nœuds (14:45 — 45 min)

**Ce que tu fais** :
- S'assurer que tout le monde voit `number_of_nodes: 3` dans `_cluster/health`
- Pointer `_cat/shards` : "Observez que les primaires et réplicas sont sur des nœuds différents"
- Pour ceux qui vont vite : simulation de panne de nœud (bonus)

---

## Pause (15:30 — 15 min)

---

## TP8 — Routage : démonstration (15:45 — 45 min)

**Ce que tu dis avant le TP** :
> "On vient de voir l'algorithme de routage en théorie. Dans ce TP, on va le voir en pratique. On va créer deux index identiques — l'un avec routing automatique, l'autre avec routing forcé par catégorie — et observer la distribution des documents dans les shards."

**Ce que tu fais pendant le TP** :
- Guider les participants sur `_cat/shards` après l'indexation : "Observez le déséquilibre"
- Pointer la différence dans les shards interrogés avec/sans `?routing=`
- Conclure : "Le routing custom peut être un avantage ou un piège selon votre modèle de données"

---

## Récap Jour 2 + Q&A + preview Jour 3 (16:30 — 30 min)

**Questions orales de vérification** :
1. "Qu'est-ce que FLS ? Comment on exclut un champ ?"
2. "Quelle est la formule de routage par défaut ?"
3. "Pourquoi ne peut-on pas changer le nombre de primary shards ?"
4. "Qu'est-ce qu'un hotspot dans le contexte du routing ?"
5. "Quel est le quorum pour 3 nœuds master-eligible ?"

**Preview Jour 3** :
> "Demain matin on attaque les agrégations — statistiques, buckets, imbriquées, pipeline. C'est la base de tout ce qu'on visualise dans Dashboards. L'après-midi : Dashboards, reindex et cycle de vie des index avec ISM."
