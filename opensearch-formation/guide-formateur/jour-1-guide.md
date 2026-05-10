# Jour 1 — Guide formateur

## Timing global

| Heure | Durée | Activité | Type |
|-------|-------|----------|------|
| 09:00–09:30 | 30 min | Accueil, présentation, tour de table | Q/A |
| 09:30–09:45 | 15 min | Démo live ice breaker | Démo live |
| 09:45–10:30 | 45 min | Chapitre 1 : Introduction à OpenSearch | Cours |
| 10:30–10:45 | 15 min | Pause | Pause |
| 10:45–11:30 | 45 min | Chapitre 2 : Installation & Configuration | Cours |
| 11:30–12:15 | 45 min | TP1 : Installation en local | TP |
| 12:15–13:30 | 75 min | Déjeuner | Déjeuner |
| 13:30–14:15 | 45 min | Chapitre 3a : Fonctionnement d'OpenSearch | Cours |
| 14:15–15:00 | 45 min | TP2 : CRUD & API REST | TP |
| 15:00–15:15 | 15 min | Pause | Pause |
| 15:15–15:45 | 30 min | Chapitre 3b : Query DSL & Agrégations | Cours |
| 15:45–16:30 | 45 min | TP3 : Requêtes & Agrégations | TP |
| 16:30–17:00 | 30 min | Récap Jour 1, Q&A, preview Jour 2 | Q/A |

---

## Slide 1 : Titre de la formation

**Timing** : 3 min (pendant que les participants s'installent)

**Ce que tu dis** :
> "Bonjour à tous, bienvenue dans cette formation OpenSearch 3.6. Trois jours ensemble pour explorer ce moteur de recherche de fond en comble — de l'installation jusqu'à la sécurisation d'un cluster en production. Mon objectif, c'est que vous repartiez d'ici avec assez de pratique pour être autonomes dans votre quotidien. On va beaucoup manipuler, peu lire des slides, et le fil rouge de la formation c'est la construction progressive d'un moteur de recherche e-commerce. Installez-vous confortablement, posez vos questions quand vous voulez — il n'y a pas de question bête ici."

**Points clés** :
- Rappeler le programme de la journée (affiché sur le slide)
- Mentionner les horaires : 9h–17h, pauses à 10h30, 15h00 et déjeuner 12h15–13h30
- Indiquer où se trouve le support, les labs, le drive partagé

**Transition** :
> "Avant de commencer, j'aimerais qu'on se présente rapidement. On va faire un tour de table."

---

## Slide 2 : Plan du jour

**Timing** : 2 min

**Ce que tu dis** :
> "Voilà ce qu'on va faire aujourd'hui. Matin : on part de zéro, on comprend ce qu'est OpenSearch, pourquoi ça existe, et on l'installe. Après-midi : on entre dans les détails — comment ça fonctionne en interne, les indices, les shards, et on fait nos premières vraies requêtes de recherche. La journée se termine par un récap et on prévisualisera ce qui arrive demain."

**Points clés** :
- Associer chaque bloc à un TP concret
- Mentionner que le fil rouge (e-commerce) sera présent dès le TP1

**Transition** :
> "Mais d'abord, présentons-nous."

---

## Slide 3 : Tour de table

**Timing** : 20–25 min (selon le nombre de participants)

**Ce que tu dis** :
> "Je voudrais que chacun se présente en 2-3 minutes : votre prénom, votre rôle dans votre entreprise, votre expérience avec les moteurs de recherche en général — vous avez peut-être déjà utilisé Elasticsearch, Solr, ou même juste LIKE en SQL — et ce que vous espérez emporter de ces trois jours. Ça m'aide à adapter le niveau et les exemples."

**Points clés** :
- Écouter attentivement et noter les profils sur une feuille (dev, ops, data, chef de projet...)
- Identifier les niveaux : débutant complet / déjà utilisé ES / connaît OS
- Repérer les cas d'usage métier spécifiques (logs, e-commerce, RH, légal...)
- Adapter mentalement les exemples à venir

**Signal d'alerte** : Si tout le monde dit "je connais Elasticsearch", passer plus vite sur les bases et enrichir les comparaisons ES vs OS. Si aucun participant ne connaît, ralentir le rythme du Chapitre 1.

**Questions fréquentes** :
- Q: "Est-ce qu'OpenSearch est compatible avec Elasticsearch ?" → R: "Très bonne question, on y répond dans 20 minutes avec une démo."
- Q: "On va utiliser quel OS ?" → R: "On travaille avec Docker, donc ça marchera pareil sur Mac, Linux et Windows."

**Transition** :
> "Parfait, merci à tous. Maintenant je vais vous montrer quelque chose qui va peut-être vous surprendre avant même qu'on parle de cours."

---

## Slide 4 : Démo live ice breaker

**Timing** : 15 min

**Ce que tu dis** :
> "Je vais faire quelque chose de très simple. Je vais lancer une requête contre un cluster OpenSearch — celui qu'on va tous utiliser — et on va voir ce que ça donne. Pas besoin de comprendre chaque mot maintenant, c'est juste pour mettre les mains dedans tout de suite."

**Demo — séquence exacte** :

1. Ouvrir un terminal. Vérifier que Docker tourne :
```bash
docker compose -f infrastructure/docker-compose.yml up -d
```

2. Attendre le healthcheck (environ 30 secondes), puis :
```bash
curl -s http://localhost:9200/ | python3 -m json.tool
```
> "Regardez ce que ça retourne : le nom du cluster, la version — ici 3.6 — et quelques métadonnées. OpenSearch répond en JSON, toujours."

3. Indexer un document :
```bash
curl -s -X POST "http://localhost:9200/produits/_doc" \
  -H 'Content-Type: application/json' \
  -d '{"nom": "MacBook Pro", "prix": 2499, "categorie": "Informatique"}' \
  | python3 -m json.tool
```
> "Je viens de créer un index 'produits' et d'y insérer un document. OpenSearch a généré un ID automatiquement. C'est aussi simple que ça."

4. Rechercher :
```bash
curl -s "http://localhost:9200/produits/_search?q=MacBook" | python3 -m json.tool
```
> "Et là je le retrouve avec une recherche plein texte. Notez le champ '_score' : c'est le score de pertinence. On va passer beaucoup de temps sur ce concept."

**Anecdote à partager** :
> "La première fois que j'ai vu ça, j'étais habitué aux bases de données relationnelles. Ce qui m'a bluffé, c'est que ça marche instantanément, sans schéma défini à l'avance. On verra que c'est une force... mais aussi un piège."

**Questions fréquentes** :
- Q: "C'est quoi le `_doc` dans l'URL ?" → R: "C'est le type de document. Depuis ES 7 et OS, il n'y a plus qu'un seul type par index, qui s'appelle `_doc` par convention. On en reparle au Chapitre 3."
- Q: "Pourquoi `python3 -m json.tool` ?" → R: "Juste pour formater le JSON dans le terminal. La Dev Tools Console de Dashboards fait ça automatiquement."

**Transition** :
> "Voilà la promesse d'OpenSearch en 3 commandes. Maintenant comprendre ce qui se passe derrière, c'est l'objet du Chapitre 1."

---

## Slide 5 : Chapitre 1 — Introduction à OpenSearch (page de titre)

**Timing** : 1 min

**Ce que tu dis** :
> "Chapitre 1. On va répondre à trois questions fondamentales : qu'est-ce qu'OpenSearch, d'où ça vient, et pourquoi l'utiliser plutôt qu'autre chose."

---

## Slide 6 : Objectifs du Chapitre 1

**Timing** : 1 min

**Ce que tu dis** :
> "À la fin de ce chapitre, vous saurez expliquer ce qu'est OpenSearch, sa relation avec Elasticsearch et Apache Lucene, les cas d'usage typiques, et les alternatives. Ce sont les bases conceptuelles qu'on réutilisera toute la formation."

---

## Slide 7 : Qu'est-ce qu'OpenSearch ?

**Timing** : 6 min

**Ce que tu dis** :
> "OpenSearch est un moteur de recherche et d'analyse distribué, open source, basé sur Apache Lucene. C'est une surcouche qui apporte la distribution, la haute disponibilité et une API REST au-dessus de Lucene. Retenez trois mots clés : distribué, orienté document, et temps réel."

**Points clés** :
- **Distribué** : les données sont réparties sur plusieurs nœuds et plusieurs machines
- **Orienté document** : on stocke des documents JSON, pas des lignes dans des tables
- **Temps quasi-réel** : un document indexé est recherchable en moins d'une seconde (par défaut 1s de refresh)

**Anecdote** :
> "Apache Lucene a été créé par Doug Cutting en 1999. Il a aussi créé Hadoop. C'est un homme qui aime les données distribuées. Lucene est la bibliothèque Java qui fait le vrai travail de recherche ; OpenSearch, c'est l'habillage qui permet de l'utiliser à grande échelle via HTTP."

**Questions fréquentes** :
- Q: "C'est quoi la différence avec une base de données classique ?" → R: "Une BDD relationnelle optimise pour les transactions ACID et les jointures. OpenSearch optimise pour la recherche full-text et les agrégations analytiques. Ce ne sont pas des concurrents — ils sont complémentaires."

---

## Slide 8 : Histoire — De Elasticsearch à OpenSearch

**Timing** : 7 min

**Ce que tu dis** :
> "Pour comprendre OpenSearch, il faut un peu d'histoire. Elasticsearch a été créé par Shay Banon en 2010 comme wrapper REST autour de Lucene. Il est devenu très populaire, utilisé par des milliers d'entreprises pour la recherche et les logs. En 2021, Elastic a changé la licence d'Elasticsearch — passage de l'Apache 2.0 vers SSPL, une licence qui limite l'utilisation commerciale des services cloud. Amazon, grand utilisateur d'ES via son service managé, a réagi en forkant le projet à la version 7.10.2 et en créant OpenSearch, sous licence Apache 2.0. Depuis, les deux projets évoluent indépendamment."

**Points clés** :
- Fork officiel en avril 2021
- OpenSearch 1.0 sortie en juillet 2021
- Aujourd'hui : OpenSearch 3.6 — avec des fonctionnalités qui n'existent pas dans ES (Vector Search, ML Commons...)
- Licence Apache 2.0 : totalement libre, y compris pour usage commercial cloud

**Signal d'alerte** : Si un participant travaille déjà avec Elasticsearch managé (Elastic Cloud), insister sur la coexistence possible — ce n'est pas forcément l'un ou l'autre.

**Questions fréquentes** :
- Q: "Est-ce qu'OpenSearch est 100% compatible avec Elasticsearch ?" → R: "À partir de la version 2.x, les APIs ont divergé. Les clients ES 7.x fonctionnent souvent avec OS, mais les clients récents ES 8.x non. Il existe un client officiel OpenSearch pour tous les langages."
- Q: "Qui maintient OpenSearch aujourd'hui ?" → R: "Amazon est le principal contributeur, mais la gouvernance est ouverte — il y a des contributions de SAP, Aryn, Aiven, et d'autres."

---

## Slide 9 : Architecture Lucene

**Timing** : 6 min

**Ce que tu dis** :
> "Plongeons une seconde dans Lucene pour comprendre pourquoi la recherche plein texte est rapide. Lucene organise les données dans des structures appelées 'inverted index' — index inversé en français. Imaginez un livre avec un index à la fin : vous cherchez un mot et il vous dit à quelle page il apparaît. C'est exactement ça. Au lieu d'aller lire chaque document pour chercher un mot, Lucene maintient un dictionnaire de tous les mots et pour chaque mot la liste des documents qui le contiennent."

**Points clés** :
- Index inversé : terme → liste de documents (+ positions, fréquences)
- L'indexation est coûteuse (on analyse le texte, on construit le dictionnaire)
- La recherche est rapide (on consulte simplement le dictionnaire)
- Les segments Lucene : des morceaux d'index immutables qui sont fusionnés périodiquement

**Schéma à dessiner au tableau** :
```
Document 1: "OpenSearch est rapide"
Document 2: "OpenSearch analyse les données"

Index inversé:
"opensearch" → [doc1, doc2]
"rapide"     → [doc1]
"analyse"    → [doc2]
"données"    → [doc2]
```

**Questions fréquentes** :
- Q: "Pourquoi les segments sont-ils immutables ?" → R: "C'est un choix de performance. Modifier un fichier en place est complexe. Lucene préfère écrire de nouveaux segments et fusionner ensuite. C'est pourquoi les suppressions ne libèrent de l'espace qu'après un merge."

---

## Slide 10 : Cas d'usage

**Timing** : 5 min

**Ce que tu dis** :
> "OpenSearch excelle dans plusieurs familles de cas d'usage. Je vous en présente quatre grandes familles."

**Points clés** :

1. **Recherche applicative** : moteur de recherche sur un site e-commerce, portail documentaire, base de connaissances. C'est notre fil rouge.
2. **Observabilité** : centralisation de logs applicatifs, métriques système, traces distribuées. La stack ELK/EOS est incontournable dans ce domaine.
3. **Analytique** : dashboards temps réel, agrégations sur de grands volumes, reporting. OpenSearch Dashboards est notre outil.
4. **Recherche vectorielle / ML** : semantic search, recommendation, détection d'anomalies. C'est la grande nouveauté des versions 2.x et 3.x.

**Anecdote** :
> "Netflix utilise un cluster Elasticsearch/OpenSearch avec des centaines de milliards de documents pour indexer chaque interaction utilisateur. GitHub utilise ES pour la recherche de code. Wikipedia utilise Elasticsearch pour son moteur de recherche."

**Questions fréquentes** :
- Q: "OpenSearch peut remplacer une base de données ?" → R: "Non. Il ne garantit pas les transactions ACID. C'est une source de données secondaire — on y pousse les données depuis une source primaire (PostgreSQL, MySQL...) pour les rendre recherchables."

---

## Slide 11 : Comparaison avec les alternatives

**Timing** : 5 min

**Ce que tu dis** :
> "Il existe d'autres moteurs de recherche. Je vous donne une vue rapide pour que vous puissiez situer OpenSearch dans le paysage."

**Tableau de comparaison** (à commenter oralement) :

| Moteur | Points forts | Limites | Typique pour |
|--------|-------------|---------|-------------|
| **OpenSearch** | Licence libre, distribué, riche en features | Complexité opérationnelle | E-commerce, logs, analytique |
| **Elasticsearch** | Même base technique, meilleure doc | Licence SSPL restrictive | Idem, si déjà investi ES |
| **Solr** | Mature, Lucene natif | UX moins moderne | GED, recherche documentaire |
| **Meilisearch** | Simple, ultra-rapide setup | Moins de features avancées | Petits projets, prototypes |
| **Typesense** | Très simple, typo-tolérant | Volume limité | Projets légers |
| **pgvector** | Dans PostgreSQL | Pas full-text natif | Recherche vectorielle pure |

**Transition** :
> "On a le contexte. Maintenant je veux vous montrer l'architecture interne pour qu'on comprenne comment ça tient ensemble."

---

## Slide 12 : Concepts fondamentaux (aperçu)

**Timing** : 8 min

**Ce que tu dis** :
> "Avant la pause, je veux poser six concepts clés. On les approfondit tous après le déjeuner, mais il faut les avoir en tête."

**Points clés** — à expliquer l'un après l'autre :

1. **Nœud (node)** : une instance OpenSearch. Un cluster en contient un ou plusieurs.
2. **Cluster** : ensemble de nœuds qui travaillent ensemble. Ils partagent les données et la charge.
3. **Index** : l'équivalent d'une table en SQL. Contient des documents du même type.
4. **Document** : unité de données, un objet JSON. L'équivalent d'une ligne en SQL.
5. **Shard** : fragment d'un index. Un index est découpé en shards distribués sur les nœuds. Deux types : primaires (données originales) et réplicas (copies).
6. **Mapping** : schéma qui décrit les champs d'un document et leurs types (text, keyword, integer, date...).

**Analogie SQL à utiliser** :
```
SQL           →  OpenSearch
Base          →  Cluster
Table         →  Index
Ligne         →  Document
Colonne       →  Champ (field)
Index SQL     →  Shard Lucene
```

**Signal d'alerte** : Si quelqu'un confond "index OpenSearch" et "index SQL", clarifier immédiatement — c'est une source de confusion permanente. L'index OpenSearch est le conteneur de documents, pas une structure d'optimisation de requête.

**Questions fréquentes** :
- Q: "Combien de shards pour un index ?" → R: "La règle empirique : viser 20–50 Go par shard. Par défaut OpenSearch crée 1 shard primaire depuis la v2.x (avant c'était 5). On voit ça en détail au Chapitre 3."
- Q: "Un réplica c'est une copie exacte ?" → R: "Oui. Chaque shard primaire a zéro à N réplicas. Les réplicas servent à la haute disponibilité et à scaler les lectures."

---

## Slide 13 : Démo live — Exploration du cluster

**Timing** : 8 min

**Ce que tu dis** :
> "On fait une pause démo pour ancrer tout ça. Je vais vous montrer les APIs Cat qui donnent des informations sur l'état du cluster — c'est ce que vous utiliserez tous les jours en production."

**Demo — séquence exacte** :

```bash
# État du cluster
curl -s "http://localhost:9200/_cluster/health?pretty"
```
> "Regardez 'status': green veut dire que tous les shards primaires ET réplicas sont assignés. Yellow : primaires OK, réplicas pas assignés — normal sur un seul nœud. Red : des shards primaires manquent — urgence."

```bash
# Liste des nœuds
curl -s "http://localhost:9200/_cat/nodes?v&h=name,ip,heap.percent,ram.percent,cpu,node.role"
```
> "Ici notre nœud unique. Le rôle 'dimr' veut dire : data, ingest, master-eligible, et remote-cluster-client. Sur un cluster de production, ces rôles sont séparés."

```bash
# Liste des indices (avec l'index 'produits' créé avant)
curl -s "http://localhost:9200/_cat/indices?v"
```
> "Voyez le 'health' yellow sur notre index 'produits' — c'est normal, on a un réplica qui ne peut pas s'assigner sur un nœud unique."

**Transition** :
> "C'est la pause. Quinze minutes et on reprend sur le Chapitre 2 — comment installer et configurer OpenSearch."

---

## Slide 14 : Quiz Chapitre 1

**Timing** : 3 min (juste avant la pause ou juste après)

**Ce que tu dis** :
> "Avant de partir en pause, petit quiz à mains levées — pas de pression."

**Questions** :
1. "OpenSearch est basé sur quelle bibliothèque Java ?" → Lucene
2. "Quelle est la licence d'OpenSearch ?" → Apache 2.0
3. "Quelle est la différence entre un index et un document ?" → L'index est le conteneur, le document est l'unité de données
4. "Que signifie 'status: yellow' sur un cluster health ?" → Primaires OK, réplicas non assignés

**Signal d'alerte** : Si personne ne sait répondre à la question 4, c'est que le concept de shard/réplica n'est pas ancré. Prendre 2 minutes pour reexpliquer avec le schéma.

---

## Slide 15 : Récap Chapitre 1

**Timing** : 2 min

**Ce que tu dis** :
> "En résumé : OpenSearch est un fork Apache 2.0 d'Elasticsearch 7.10, basé sur Lucene. Il excelle pour la recherche full-text, les logs et l'analytique. Les six concepts fondamentaux sont nœud, cluster, index, document, shard et mapping. On va tous les retrouver dans le TP tout à l'heure. Questions avant la pause ?"

---

## [PAUSE 10:30–10:45]

---

## Slide 16 : Chapitre 2 — Installation & Configuration (titre)

**Timing** : 1 min

**Ce que tu dis** :
> "Chapitre 2. On va voir comment installer OpenSearch — plusieurs méthodes — et les paramètres de configuration essentiels. C'est la base pour que votre cluster démarre et soit stable."

---

## Slide 17 : Méthodes d'installation

**Timing** : 7 min

**Ce que tu dis** :
> "Il y a quatre façons d'installer OpenSearch. Dans cette formation on utilise Docker parce que c'est le plus rapide et le plus reproductible. En production, vous utiliserez probablement packages ou Kubernetes."

**Points clés** :

1. **Docker / Docker Compose** (on l'utilise) :
   - Avantages : isolation, reproductibilité, multiplateforme
   - Usage : développement, formation, POC
   - `docker compose up -d`

2. **Packages RPM / DEB** :
   - Avantages : intégration systemd, mise à jour via apt/yum
   - Usage : déploiement Linux production sans conteneurs

3. **Archive tar.gz** :
   - Avantages : flexibilité totale, pas besoin de droits root
   - Usage : tests, environnements contraints

4. **Kubernetes / Helm / Operator** :
   - Avantages : scaling automatique, rolling updates, self-healing
   - Usage : production cloud-native

**Conditions système à connaître** :
- `vm.max_map_count` doit être ≥ 262144 (Linux)
- Mémoire heap : 50% de la RAM disponible, max 32 Go (JVM compressed oops)
- `ulimit -n` : au moins 65536 file descriptors

**Questions fréquentes** :
- Q: "Pourquoi la limite de 32 Go de heap ?" → R: "Au-delà de ~32 Go, la JVM désactive les 'compressed oops' — les pointeurs d'objets passent de 4 à 8 octets, ce qui augmente la consommation mémoire. Il vaut mieux deux nœuds à 30 Go qu'un seul à 64 Go."

---

## Slide 18 : docker-compose.yml expliqué

**Timing** : 8 min

**Ce que tu dis** :
> "Regardons le fichier docker-compose.yml qu'on va utiliser pour le TP. Je vais vous expliquer chaque section importante."

**Demo — ouvrir le fichier** :
```bash
cat infrastructure/docker-compose.yml
```

**Points à commenter** :
```yaml
environment:
  - cluster.name=ecommerce-search        # Nom du cluster
  - node.name=opensearch-node1           # Nom du nœud
  - discovery.type=single-node           # Pas de quorum nécessaire
  - bootstrap.memory_lock=true           # Interdit le swap mémoire
  - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m"  # Heap JVM
  - plugins.security.disabled=true       # On simplifie pour la formation
```

> "Notez `plugins.security.disabled=true`. En formation c'est pratique — pas d'authentification. En production, jamais. On verra la sécurité au Jour 3."

> "Le `bootstrap.memory_lock=true` est crucial. Si OpenSearch peut swapper sur le disque, les performances s'effondrent et les GC pauses explosent. On verrouille la mémoire en RAM."

**Signal d'alerte** : Si un participant dit "ça ne démarre pas chez moi", les causes les plus fréquentes sont : port 9200 ou 5601 déjà utilisé, `vm.max_map_count` trop bas sur Linux, ou mémoire insuffisante.

---

## Slide 19 : opensearch.yml — Configuration principale

**Timing** : 8 min

**Ce que tu dis** :
> "Le fichier de configuration principal d'OpenSearch, c'est `opensearch.yml`. Je vous montre les paramètres les plus importants."

**Points clés** (à écrire au tableau ou montrer dans le fichier) :

```yaml
# Identité du cluster
cluster.name: ecommerce-search
node.name: node-1

# Réseau
network.host: 0.0.0.0     # Écouter sur toutes les interfaces
http.port: 9200            # API REST
transport.port: 9300       # Communication inter-nœuds

# Discovery (comment les nœuds se trouvent)
discovery.seed_hosts: ["node-1", "node-2", "node-3"]
cluster.initial_cluster_manager_nodes: ["node-1"]

# Chemins
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
```

**Paramètres dynamiques vs statiques** :
- Statiques : nécessitent un redémarrage (`cluster.name`, `node.name`, `path.*`)
- Dynamiques : modifiables via API sans redémarrage (`action.auto_create_index`, paramètres de shards...)

```bash
# Modifier un paramètre dynamiquement
PUT _cluster/settings
{
  "persistent": {
    "indices.recovery.max_bytes_per_sec": "100mb"
  }
}
```

**Questions fréquentes** :
- Q: "Quelle différence entre `persistent` et `transient` dans les settings de cluster ?" → R: "Persistent : survit aux redémarrages, stocké dans le cluster state. Transient : perdu au redémarrage. Utilisez toujours `persistent` pour vos vraies configurations."

---

## Slide 20 : JVM et performances

**Timing** : 6 min

**Ce que tu dis** :
> "OpenSearch tourne sur la JVM. La configuration JVM est dans `config/jvm.options`. Le paramètre le plus important : la taille du heap."

**Points clés** :
```
-Xms4g   # Heap minimum = 4 Go
-Xmx4g   # Heap maximum = 4 Go
```
> "Mettre Xms = Xmx évite que la JVM alloue et libère de la mémoire dynamiquement — ça cause des pauses GC. On fixe les deux à la même valeur."

**Règles d'or** :
1. Ne jamais dépasser 50% de la RAM du serveur pour le heap
2. Ne jamais aller au-delà de 32 Go
3. Laisser le reste à l'OS pour le file system cache (Lucene en profite massivement)

**Anecdote** :
> "J'ai vu des clusters en production avec `-Xmx64g`. Les GC stop-the-world duraient 10–15 secondes. Tout le cluster semblait mort périodiquement. La solution était simple : réduire le heap et scaler horizontalement."

---

## Slide 21 : Plugins et extensions

**Timing** : 5 min

**Ce que tu dis** :
> "OpenSearch a un système de plugins riche. Certains sont fournis par défaut, d'autres s'installent."

**Plugins notables** :
- `opensearch-security` : authentification, autorisation, TLS (installé par défaut)
- `opensearch-ml` : ML Commons, modèles de language, embedding
- `opensearch-knn` : recherche vectorielle k-NN
- `opensearch-anomaly-detection` : détection d'anomalies automatique
- `opensearch-sql` : requêtes SQL sur vos indices

```bash
# Lister les plugins installés
GET _cat/plugins?v
```

**Transition** :
> "On a les bases théoriques. Il est 11h30, c'est l'heure de mettre les mains dedans. TP1 — installation et exploration du cluster."

---

## Slide 22 : Démo install (pré-TP)

**Timing** : 5 min (intégrée avant le TP1)

**Ce que tu dis** :
> "Avant que vous fassiez le TP, je fais la démo une fois en entier pour que vous voyez le déroulé. Regardez, ne tapez pas encore."

**Demo — séquence complète** :

```bash
# 1. Aller dans le répertoire infrastructure
cd /chemin/vers/opensearch-formation/infrastructure

# 2. Lancer Docker Compose
docker compose up -d

# 3. Vérifier que les conteneurs tournent
docker compose ps

# 4. Attendre le health check puis vérifier
curl -s http://localhost:9200/_cluster/health | python3 -m json.tool

# 5. Ouvrir Dashboards dans le navigateur
open http://localhost:5601
```

> "Je vous montre aussi la Dev Tools Console dans Dashboards — c'est là que vous ferez la plupart de vos requêtes."

**Dans la Dev Tools Console** :
```
GET _cluster/health
GET _cat/nodes?v
GET _cat/indices?v
```

---

## Slide 23 : TP1 — Installation en local

**Timing** : 45 min (11:30–12:15)

**Ce que tu dis** :
> "À vous de jouer. Le sujet du TP est dans le dossier `labs/tp1-installation/README.md`. Vous avez 45 minutes. Travaillez à votre rythme — certains finiront plus vite et pourront faire le bonus. Je passe dans les rangs. Levez la main si vous bloquez."

**Checklist de circulation formateur** :
- [ ] Vérifier que Docker tourne sur chaque poste (surtout Windows)
- [ ] Sur Linux : rappeler `sysctl -w vm.max_map_count=262144`
- [ ] Vérifier que le port 9200 n'est pas occupé (`lsof -i:9200`)
- [ ] S'assurer que Dashboards répond sur 5601
- [ ] Rappeler l'exercice 5 sur `action.auto_create_index` : le remettre à null !

**Problèmes fréquents** :
- Docker Desktop pas démarré (Mac/Windows) → demander de l'ouvrir
- "Error: address already in use" → `docker compose down` pour nettoyer un vieux conteneur
- Dashboard qui met du temps → patience, le healthcheck est stricte, attendre jusqu'à 2 minutes
- Credentials oubliés → admin / Formation@OpenSearch2024!

**Signal d'alerte** : Si plus de 3 personnes bloquent sur le même exercice, faire un point collectif plutôt que de passer de poste en poste.

**Transition** :
> "C'est l'heure du déjeuner. À 13h30 on reprend sur le fonctionnement interne d'OpenSearch — la partie la plus importante conceptuellement."

---

## [DÉJEUNER 12:15–13:30]

---

## Slide 24 : Quick quiz post-déjeuner (Chapitre 2)

**Timing** : 3 min

**Ce que tu dis** :
> "Bienvenue de retour. Deux questions rapides pour remettre le moteur en route."

**Questions** :
1. "Quel fichier configure OpenSearch au démarrage ?" → `opensearch.yml`
2. "Pourquoi on ne dépasse pas 32 Go de heap JVM ?" → Compressed oops désactivés au-delà
3. "Que fait `bootstrap.memory_lock: true` ?" → Empêche le swap de la mémoire heap

---

## Slide 25 : Récap Chapitre 2

**Timing** : 2 min

**Ce que tu dis** :
> "Chapitre 2 en résumé : Docker est la méthode la plus simple pour commencer. Les paramètres critiques sont `cluster.name`, `network.host`, `discovery`, la taille du heap, et `vm.max_map_count`. On distingue les paramètres statiques (redémarrage requis) des dynamiques (API). On passe maintenant au cœur du sujet : comment OpenSearch fonctionne en interne."

---

## Slide 26 : Chapitre 3a — Fonctionnement d'OpenSearch (titre)

**Timing** : 1 min

**Ce que tu dis** :
> "Chapitre 3a. C'est le chapitre le plus dense conceptuellement de la journée. On va comprendre les index, les shards, les mappings et le cycle de vie d'un document. Accrochez-vous, c'est ce qui fait la différence entre quelqu'un qui utilise OpenSearch et quelqu'un qui le maîtrise."

---

## Slide 27 : Index et mappings

**Timing** : 8 min

**Ce que tu dis** :
> "Un index OpenSearch, c'est un conteneur logique pour vos documents. Pensez à lui comme à une table, mais beaucoup plus flexible. Quand vous créez un index, vous pouvez définir un mapping — le schéma — à l'avance, ou laisser OpenSearch le deviner automatiquement. C'est ce qu'on appelle le dynamic mapping."

**Demo — créer un index avec mapping explicite** :
```json
PUT /produits
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "nom": { "type": "text", "analyzer": "french" },
      "prix": { "type": "float" },
      "categorie": { "type": "keyword" },
      "en_stock": { "type": "boolean" },
      "date_creation": { "type": "date" }
    }
  }
}
```

**Différence text vs keyword — c'est fondamental** :
- `text` : analysé, tokenisé. Utilisé pour la recherche full-text. On peut chercher dedans.
- `keyword` : non analysé, valeur exacte. Utilisé pour les agrégations, les tris, les filtres exacts.

> "La règle : si vous voulez faire `GROUP BY` ou trier, utilisez `keyword`. Si vous voulez faire une recherche textuelle, utilisez `text`. Souvent on veut les deux — on utilise alors un champ multi-field."

**Multi-field** :
```json
"titre": {
  "type": "text",
  "fields": {
    "keyword": { "type": "keyword" }
  }
}
```

**Signal d'alerte** : La confusion text/keyword est LA source d'erreur numéro 1 des débutants. Si quelqu'un essaie de faire une agrégation sur un champ `text`, il obtiendra une erreur. Insister sur ce point.

**Questions fréquentes** :
- Q: "Peut-on modifier le mapping après création ?" → R: "Pour les types de champs existants, non — ça nécessite une réindexation. On peut ajouter de nouveaux champs. C'est pourquoi bien réfléchir au mapping avant de commencer est important."

---

## Slide 28 : Shards et réplicas

**Timing** : 10 min

**Ce que tu dis** :
> "La distribution des données dans OpenSearch repose sur les shards. Un index est découpé en N shards primaires — c'est fixé à la création et ne change pas (sauf avec l'API split/shrink). Chaque shard primaire peut avoir 0 à N réplicas."

**Schéma à dessiner** :
```
Index "produits" — 3 shards primaires, 1 réplica

Nœud 1: [P0] [R1] [R2]
Nœud 2: [P1] [R0] [R2]  ← P = Primaire, R = Réplica
Nœud 3: [P2] [R0] [R1]
```

> "Règle fondamentale : un réplica d'un shard ne peut jamais être sur le même nœud que son primaire. Si c'était le cas, perdre ce nœud ferait perdre les deux copies."

**Routing** : comment OpenSearch sait quel shard contient un document ?
```
shard = hash(document_id) % number_of_shards
```
> "C'est deterministe. Pour un document avec id='abc123', c'est toujours le même shard. C'est pourquoi on ne peut pas changer le nombre de shards primaires après coup — la formule de routing donnerait des mauvais résultats."

**Taille idéale d'un shard** : 20–50 Go. Au-delà, les opérations de merge et recovery deviennent longues.

**Overhead shard** : chaque shard a un coût en RAM (~few MB de metadata). Un index avec 1000 shards sur un cluster à 3 nœuds va saturer la mémoire même avec peu de données. Évitez le "shard proliferation".

**Questions fréquentes** :
- Q: "Pourquoi OpenSearch 2.x+ crée 1 shard par défaut au lieu de 5 ?" → R: "Pour éviter le over-sharding sur les petits clusters. 5 shards vides x 1000 indices = 5000 shards, c'est trop pour un petit cluster."
- Q: "Combien de réplicas en production ?" → R: "Au minimum 1. Pour les données critiques : 2. Plus de réplicas = meilleures lectures (chaque réplica peut servir des requêtes) mais coût en stockage et en indexation."

---

## Slide 29 : Cycle de vie d'un document

**Timing** : 7 min

**Ce que tu dis** :
> "Comment un document va de votre client jusqu'au disque ? C'est important pour comprendre les garanties de durabilité et de cohérence."

**Étapes** :
1. Client envoie une requête `PUT /index/_doc/id` au **nœud coordinateur**
2. Le coordinateur calcule le shard cible via le routing
3. La requête est forwardée au **nœud qui contient le shard primaire**
4. Le primaire écrit dans son **transaction log (translog)** — durabilité immédiate
5. Le primaire envoie en parallèle aux **shards réplicas**
6. Quand tous les réplicas ont confirmé, l'ACK est renvoyé au client
7. Périodiquement (défaut : 1 seconde) : **refresh** — les données du buffer mémoire passent dans un segment Lucene et deviennent recherchables
8. Périodiquement (défaut : 30 minutes ou 512 Mo de translog) : **flush** — les segments sont écrits sur le disque et le translog est purgé

**Points importants** :
- Après le `200 OK`, le document est **durable** (dans le translog) mais pas encore **visible** (pas encore refreshé)
- Le `?refresh=true` force un refresh immédiat — pratique pour les tests, coûteux en production
- Le `?refresh=wait_for` attend le prochain refresh automatique

**Questions fréquentes** :
- Q: "Que se passe-t-il si un nœud tombe entre l'écriture du translog et le flush ?" → R: "Au redémarrage, OpenSearch rejoue le translog pour récupérer les documents non flushés. C'est le mécanisme de durabilité."

---

## Slide 30 : Templates d'index

**Timing** : 5 min

**Ce que tu dis** :
> "En production, vous avez rarement un seul index. Vous avez souvent des indices par date : `logs-2024-01`, `logs-2024-02`... Les index templates permettent de définir settings et mappings qui s'appliquent automatiquement à tous les nouveaux indices correspondant à un pattern."

```json
PUT _index_template/logs-template
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "timestamp": { "type": "date" },
        "level": { "type": "keyword" },
        "message": { "type": "text" }
      }
    }
  }
}
```

> "Dès qu'un index dont le nom commence par 'logs-' est créé, ce template s'applique. Plus besoin de définir le mapping à chaque fois."

---

## Slide 31 : Opérations CRUD

**Timing** : 7 min

**Ce que tu dis** :
> "Les opérations de base : Create, Read, Update, Delete. Je vais les faire en live pour que vous voyez la syntaxe exacte."

**Demo — CRUD complet** :

```json
# CREATE
PUT /produits/_doc/1
{
  "nom": "Écouteurs Sony WH-1000XM5",
  "prix": 279.99,
  "categorie": "Électronique",
  "en_stock": true
}

# READ
GET /produits/_doc/1

# UPDATE (partiel — merge avec l'existant)
POST /produits/_update/1
{
  "doc": {
    "prix": 249.99
  }
}

# DELETE
DELETE /produits/_doc/1

# Vérification
GET /produits/_doc/1
```

**Bulk API — pour l'indexation en masse** :
```
POST _bulk
{ "index": { "_index": "produits", "_id": "1" } }
{ "nom": "Produit A", "prix": 10.0 }
{ "index": { "_index": "produits", "_id": "2" } }
{ "nom": "Produit B", "prix": 20.0 }
```
> "La Bulk API est indispensable pour charger des données. Elle peut traiter des milliers d'opérations en un seul appel HTTP. Notre TP1 utilise déjà des données au format NDJSON pour la Bulk API."

---

## Slide 32 : Recherche de base — Match Query

**Timing** : 5 min

**Ce que tu dis** :
> "La requête de recherche de base s'appelle `match`. C'est la brique fondamentale du Query DSL."

```json
GET /produits/_search
{
  "query": {
    "match": {
      "nom": "écouteurs sans fil"
    }
  }
}
```

> "OpenSearch analyse la chaîne 'écouteurs sans fil', la tokenise, cherche chaque token dans l'index inversé, et calcule un score de pertinence pour chaque document trouvé. Les résultats sont triés par score décroissant."

**Structure de la réponse** :
```json
{
  "took": 5,          ← temps en millisecondes
  "hits": {
    "total": { "value": 3 },
    "hits": [
      {
        "_score": 2.3,  ← score de pertinence
        "_source": { ... }  ← le document
      }
    ]
  }
}
```

---

## Slide 33 : Anatomie du score (BM25)

**Timing** : 5 min

**Ce que tu dis** :
> "Comment OpenSearch calcule-t-il le score ? Par défaut il utilise l'algorithme BM25 — Best Match 25. C'est une évolution du TF-IDF classique."

**Facteurs du score** :
- **TF (Term Frequency)** : plus un terme apparaît dans un document, plus le score monte (avec diminution des rendements)
- **IDF (Inverse Document Frequency)** : un terme rare est plus discriminant qu'un terme commun ("le", "de"...)
- **Longueur du document** : BM25 normalise par la longueur — un document court avec le terme est mieux scoré qu'un long avec le même terme

> "En pratique : 'Sony' dans un document court sur les écouteurs sera mieux scoré que 'Sony' dans un long article Wikipedia. C'est intuitif."

**Transition** :
> "On a fait TP2 tout à l'heure sur le CRUD — maintenant place au TP2 proprement dit."

---

## Slide 34 : TP2 — CRUD & API REST

**Timing** : 45 min (14:15–15:00)

**Ce que tu dis** :
> "TP2 : CRUD et API REST. Vous allez indexer vos premiers documents, les modifier, les supprimer, et faire vos premières recherches. Le sujet est dans `labs/tp2-crud-api/README.md`. 45 minutes, je passe dans les rangs."

**Checklist formateur pendant le TP** :
- [ ] Vérifier que l'index `produits` créé pendant la démo est présent (sinon le recréer en live)
- [ ] Aider sur la syntaxe Bulk API (les sauts de ligne sont importants — une erreur fréquente)
- [ ] Montrer comment utiliser la Dev Tools Console pour l'autocomplétion
- [ ] Rappeler la différence `PUT _doc/id` (avec ID) vs `POST _doc` (ID auto-généré)

**Problèmes fréquents** :
- "mapper_parsing_exception" → le type de champ dans le JSON ne correspond pas au mapping (ex. envoyer une string pour un champ `float`)
- "index_not_found_exception" → l'index n'a pas été créé, ou faute de frappe dans le nom
- Bulk API qui échoue → vérifier qu'il n'y a pas d'espace après le JSON metadata (`{ "index": {...} }` doit être suivi d'un retour à la ligne puis du document)

---

## [PAUSE 15:00–15:15]

---

## Slide 35 : Chapitre 3b — Query DSL & Agrégations (titre)

**Timing** : 1 min

**Ce que tu dis** :
> "Chapitre 3b. On va aller plus loin dans les requêtes. Le Query DSL d'OpenSearch est très puissant — c'est ce qui le différencie d'une simple recherche full-text. Et on va voir les agrégations, l'équivalent du GROUP BY en SQL."

---

## Slide 36 : Query DSL — Vue d'ensemble

**Timing** : 5 min

**Ce que tu dis** :
> "Le Query DSL structure les requêtes en deux grandes familles : les leaf queries qui cherchent dans un champ, et les compound queries qui combinent plusieurs leaf queries. Et pour chaque requête, il y a deux contextes : query (avec scoring) et filter (sans scoring, cacheable)."

**Arbre des principaux types** :

```
Query DSL
├── Leaf Queries
│   ├── Full-text : match, match_phrase, multi_match, query_string
│   └── Term-level : term, terms, range, exists, prefix, wildcard
└── Compound Queries
    ├── bool (must, should, must_not, filter)
    ├── dis_max
    └── function_score
```

**La distinction query vs filter** :
- Contexte **query** : calcule un score, les résultats sont pertinence-orderés. Utilisé pour la recherche full-text.
- Contexte **filter** : pas de score, mais le résultat est mis en cache. Utilisé pour les filtres exacts (catégorie=X, prix<100...).

> "Règle d'or : mettez dans le contexte `filter` tout ce qui est oui/non — dates, catégories, statuts. Et dans le contexte `must` ou `should` ce qui doit influencer la pertinence."

---

## Slide 37 : Bool Query

**Timing** : 7 min

**Ce que tu dis** :
> "La bool query est votre meilleure amie. Elle combine plusieurs conditions."

```json
GET /produits/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "nom": "écouteurs" } }
      ],
      "filter": [
        { "term": { "categorie": "Électronique" } },
        { "range": { "prix": { "lte": 300 } } }
      ],
      "must_not": [
        { "term": { "en_stock": false } }
      ],
      "should": [
        { "match": { "marque": "Sony" } }
      ]
    }
  }
}
```

**Sémantique de chaque clause** :
- `must` : la condition DOIT être vraie. Contribue au score.
- `filter` : la condition DOIT être vraie. N'influence PAS le score. Cache-able.
- `must_not` : la condition DOIT être fausse. N'influence pas le score.
- `should` : optionnel, mais si vrai, booste le score. Avec `minimum_should_match: 1`, au moins un doit matcher.

**Anecdote** :
> "J'utilise une analogie culinaire : `must` c'est les ingrédients obligatoires de la recette, `filter` c'est les contraintes du régime (sans gluten, pas cher), `must_not` c'est les allergies, et `should` c'est les ingrédients bonus qui font que c'est excellent mais pas indispensables."

**Questions fréquentes** :
- Q: "Quelle différence entre `must` et `filter` si les deux doivent être vrais ?" → R: "Le scoring et le cache. `filter` ne calcule pas de score → plus rapide → les résultats sont mis en cache par OpenSearch. Pour les filtres binaires (catégorie, statut...) toujours préférer `filter`."

---

## Slide 38 : Agrégations

**Timing** : 8 min

**Ce que tu dis** :
> "Les agrégations sont l'équivalent du GROUP BY en SQL. Elles permettent d'analyser les données, de calculer des statistiques, de créer des facettes pour la navigation à facettes sur les sites e-commerce."

**Trois familles d'agrégations** :

1. **Métriques** : calculs sur des valeurs numériques
   - `avg`, `min`, `max`, `sum`, `value_count`, `stats`, `percentiles`

2. **Buckets** : regroupement de documents
   - `terms` (GROUP BY sur un keyword), `date_histogram`, `range`, `histogram`

3. **Pipeline** : agrégations qui opèrent sur d'autres agrégations
   - `avg_bucket`, `derivative`, `cumulative_sum`

**Demo — agrégations imbriquées** :
```json
GET /produits/_search
{
  "size": 0,
  "aggs": {
    "par_categorie": {
      "terms": {
        "field": "categorie",
        "size": 10
      },
      "aggs": {
        "prix_moyen": {
          "avg": { "field": "prix" }
        },
        "prix_max": {
          "max": { "field": "prix" }
        }
      }
    }
  }
}
```

> "Le `size: 0` dans la requête principale : on ne veut pas les documents, juste les agrégations. C'est comme `SELECT ... GROUP BY` sans les lignes."

**Signal d'alerte** : Si un participant essaie de faire une agrégation `terms` sur un champ `text`, il aura une erreur. Rappeler text vs keyword.

**Questions fréquentes** :
- Q: "Peut-on combiner une recherche ET des agrégations ?" → R: "Oui, et c'est très puissant. La query filtre les documents sur lesquels l'agrégation s'applique. C'est comme un `WHERE ... GROUP BY` en SQL."

---

## Slide 39 : Pagination et tri

**Timing** : 4 min

**Ce que tu dis** :
> "Deux paramètres essentiels pour les résultats : `from`/`size` pour la pagination et `sort` pour le tri."

```json
GET /produits/_search
{
  "from": 0,
  "size": 10,
  "sort": [
    { "prix": { "order": "asc" } },
    { "_score": { "order": "desc" } }
  ],
  "query": { "match_all": {} }
}
```

**Limites de la pagination `from/size`** :
- Maximum 10 000 documents par défaut (`index.max_result_window`)
- Au-delà, utiliser Search After ou Scroll
- Pour la pagination profonde en production : `search_after` avec un tri stable

**Questions fréquentes** :
- Q: "Pourquoi une limite à 10 000 ?" → R: "Pour protéger le cluster. La pagination profonde nécessite de collecter `from + size` documents sur chaque shard, de les merger, puis de jeter les `from` premiers. C'est très coûteux sur de gros volumes."

---

## Slide 40 : Highlight et _source filtering

**Timing** : 4 min

**Ce que tu dis** :
> "Deux fonctionnalités pratiques pour les interfaces de recherche."

**Highlight** — met en évidence les termes recherchés dans les résultats :
```json
{
  "highlight": {
    "fields": {
      "nom": {},
      "description": { "fragment_size": 150 }
    }
  }
}
```

**_source filtering** — retourner seulement certains champs (performance) :
```json
{
  "_source": ["nom", "prix", "categorie"]
}
```

> "En production, ne retournez jamais les gros champs dont vous n'avez pas besoin. Si votre document a un champ 'description' de 10 Ko et que vous affichez une liste de résultats, filtrez-le."

---

## Slide 41 : TP3 — Requêtes & Agrégations

**Timing** : 45 min (15:45–16:30)

**Ce que tu dis** :
> "TP3 : vous allez écrire des bool queries, des range queries, et vos premières agrégations sur le catalogue produits. Le sujet est dans `labs/tp3-queries/README.md`. 45 minutes."

**Checklist formateur** :
- [ ] S'assurer que les données de produits sont bien chargées (TP2 doit être terminé)
- [ ] Rappeler la syntaxe correcte du JSON dans la Dev Tools (guillemets doubles obligatoires)
- [ ] Aider sur la compréhension du score dans les résultats
- [ ] Guider sur les agrégations imbriquées si besoin

**Problèmes fréquents** :
- Agrégation sur champ `text` → erreur. Rappeler `.keyword`
- `from/size` dépassant 10 000 → augmenter `max_result_window` ou utiliser `search_after`
- Bool query avec mauvaise syntaxe (oublier les crochets autour des clauses `must`)

**Pour les participants rapides** : les encourager à explorer les `function_score` queries ou les agrégations `date_histogram`.

---

## Slide 42 : Quiz — Récap Jour 1

**Timing** : 15 min (16:30–16:45)

**Ce que tu dis** :
> "On va clore cette première journée avec un quiz. Je pose les questions, vous répondez à main levée ou à l'oral. C'est pour vous et pour moi — pour mesurer ce qu'on a bien ancré."

**Questions** :
1. "Quelle est la différence entre un champ `text` et un champ `keyword` ?" → text : analysé, full-text search ; keyword : exact, agrégations/tri
2. "Qu'est-ce qu'un shard primaire ?" → Fragment d'un index, contient les données originales
3. "Pourquoi ne peut-on pas modifier le nombre de shards primaires après création ?" → Le routing est basé sur `hash(id) % nb_shards`
4. "Dans une bool query, quelle clause n'influence pas le score ?" → `filter` et `must_not`
5. "Que signifie `"status": "yellow"` dans `_cluster/health` ?" → Primaires OK, réplicas non assignés
6. "Comment indexer 10 000 documents efficacement ?" → Bulk API

**Signal d'alerte** : Si la question 4 est ratée par une majorité, reprendre la distinction query/filter demain matin en récap.

---

## Slide 43 : Récap Jour 1 & Preview Jour 2

**Timing** : 15 min (16:45–17:00)

**Ce que tu dis** :
> "Excellente première journée. Voici ce que vous avez accompli aujourd'hui : vous avez installé OpenSearch depuis zéro, compris l'architecture interne — indices, shards, mappings — fait vos premières opérations CRUD, et écrit des requêtes de recherche avec des agrégations. C'est solide."

**Récap des concepts clés** :
- OpenSearch = fork Apache 2.0 d'Elasticsearch, basé sur Lucene
- Index inversé = la magie derrière la recherche rapide
- Shard primaire / réplica = distribution + haute disponibilité
- text vs keyword = la distinction fondamentale des mappings
- Bool query = must / filter / must_not / should
- Agrégations = GROUP BY avec statistiques

**Preview Jour 2** :
> "Demain on va monter en puissance. Matin : les Ingest Pipelines pour transformer les données à l'ingestion, les analyseurs et tokenizers pour contrôler finement comment le texte est analysé. Après-midi : OpenSearch Dashboards — on va construire le tableau de bord e-commerce complet. C'est le jour le plus visuel."

**Mot de fin** :
> "Si vous avez des questions ce soir, notez-les — on commence demain avec un récap de 15 minutes où vous pouvez les poser. À demain !"

**Rappels pratiques** :
- Feuilles de présence : vérifier les 2 signatures du jour (matin + après-midi)
- Mettre les slides J1 en PDF sur le drive partagé ce soir
- Préparer les données pour le TP4 (vérifier que products-bulk.ndjson est dans `data/`)

---

*Fin du guide Jour 1*
