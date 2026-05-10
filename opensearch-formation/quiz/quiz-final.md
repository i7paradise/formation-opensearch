# Quiz Final — Évaluation 3 jours OpenSearch 3.6

> **Instructions** : 20 questions couvrant les 3 jours de formation. 1 seule réponse correcte par question. Durée recommandée : 20 minutes.

---

## Question 1 : Documents — `_source`

Que contient le champ `_source` dans un document OpenSearch ?

A) Uniquement les champs indexés  
B) Le document JSON original tel qu'il a été indexé  
C) Le mapping des champs  
D) Les métadonnées de recherche  

<details>
<summary>Réponse</summary>

**Réponse : B**

`_source` contient la copie complète et intacte du document JSON original envoyé à l'indexation. Il est stocké séparément de l'index inversé (Lucene). On peut le désactiver pour économiser de l'espace disque, mais cela empêche les mises à jour partielles et le reindex.
</details>

---

## Question 2 : Bool Query — Scoring

Quelle clause d'un bool query N'affecte PAS le score de pertinence `_score` ?

A) `must`  
B) `should`  
C) `filter`  
D) `match` (seul, hors bool)  

<details>
<summary>Réponse</summary>

**Réponse : C**

Le contexte `filter` exclut/inclut des documents sans modifier leur score. Il est aussi mis en cache automatiquement. `must` et `should` contribuent au score. `match` seul (D) calcule un score BM25.
</details>

---

## Question 3 : BM25 — Facteurs

Quels facteurs BM25 utilise-t-il pour calculer la pertinence ? (Choisissez la réponse la plus complète)

A) Uniquement la fréquence du terme  
B) La fréquence du terme (TF), la fréquence inverse dans les documents (IDF) et la longueur du champ  
C) Uniquement la taille du document  
D) La taille de l'index et le nombre de shards  

<details>
<summary>Réponse</summary>

**Réponse : B**

BM25 combine : **TF** (term frequency — plus le terme apparaît dans le champ, mieux c'est), **IDF** (inverse document frequency — les termes rares dans l'index sont plus discriminants), et la **longueur du champ** (un terme dans un champ court est plus pertinent que dans un texte long). L'API `_explain` décompose ce calcul.
</details>

---

## Question 4 : Shards — Immutabilité

Que se passe-t-il si on essaie de modifier le nombre de primary shards d'un index existant ?

A) La modification s'applique immédiatement  
B) Ce n'est pas possible — le nombre de primary shards est fixé à la création  
C) Il faut fermer l'index avec `_close` puis modifier  
D) Il faut utiliser l'API `_split` pour doubler le nombre  

<details>
<summary>Réponse</summary>

**Réponse : B**

Le nombre de primary shards est un paramètre **statique** et est figé à la création de l'index. C'est pourquoi il faut bien estimer ce nombre à l'avance (règle : 10–50 GB par shard). Pour changer ce nombre, il faut créer un nouvel index et réindexer avec `_reindex`. L'API `_split` (D) existe mais ne fonctionne que dans des cas très spécifiques.
</details>

---

## Question 5 : Ingest Pipelines — Grok

Quel processeur d'ingest pipeline est spécialisé dans l'extraction de champs depuis du texte libre en utilisant des patterns nommés ?

A) `dissect`  
B) `set`  
C) `grok`  
D) `rename`  

<details>
<summary>Réponse</summary>

**Réponse : C**

`grok` utilise des patterns prédéfinis (ex: `%{IP:client_ip}`, `%{HTTPD_COMMONLOG}`) pour parser des logs non structurés. `dissect` (A) est similaire mais utilise des délimiteurs fixes — plus rapide mais moins flexible que grok.
</details>

---

## Question 6 : Analyseurs — Asciifolding

Un analyseur avec `asciifolding` garantit que chercher "velo" trouve aussi les documents contenant "vélo". Cette affirmation est-elle correcte ?

A) Vrai  
B) Faux  
C) Seulement si l'analyseur est appliqué à la fois à l'indexation ET à la recherche  
D) Seulement dans le contexte `filter`  

<details>
<summary>Réponse</summary>

**Réponse : C**

L'affirmation est vraie **sous condition** : l'analyseur doit être configuré pour s'appliquer **des deux côtés** — à l'indexation (pour transformer "vélo" en "velo" dans l'index) ET à la recherche (pour transformer "velo" en "velo" avant de chercher). Par défaut, OpenSearch utilise le même analyseur dans les deux sens pour les champs `text`.
</details>

---

## Question 7 : Cluster — Quorum

Pour un cluster avec 5 nœuds master-eligible, quel est le quorum (nombre minimum de nœuds master-eligible devant être disponibles pour élire un master) ?

A) 1  
B) 2  
C) 3  
D) 4  

<details>
<summary>Réponse</summary>

**Réponse : C**

Formule : quorum = ⌊N/2⌋ + 1 = ⌊5/2⌋ + 1 = 2 + 1 = **3**. Avec 5 nœuds master-eligible, il faut que 3 soient disponibles pour élire un master et maintenir le cluster opérationnel. On peut perdre jusqu'à 2 nœuds sans perdre le cluster.
</details>

---

## Question 8 : Nœuds — Rôle Master

Quel rôle de nœud est responsable de la gestion de l'état du cluster (cluster state) et de la coordination des élections de master ?

A) `data`  
B) `ingest`  
C) `master`  
D) `coordinating`  

<details>
<summary>Réponse</summary>

**Réponse : C**

Le nœud `master` (ou master-eligible) maintient l'état global du cluster : liste des nœuds, index, mappings, allocation des shards. Il n'exécute PAS de requêtes de données. Pour les clusters de production avec plus de 5 nœuds, on recommande des nœuds master dédiés.
</details>

---

## Question 9 : Cluster — `cluster.initial_master_nodes`

Que doit-on faire de la configuration `cluster.initial_master_nodes` après que le cluster a été bootstrappé avec succès pour la première fois ?

A) La laisser telle quelle de façon permanente  
B) La supprimer du fichier de configuration  
C) La changer pour pointer uniquement sur les data nodes  
D) La réduire à un seul nœud  

<details>
<summary>Réponse</summary>

**Réponse : B**

`cluster.initial_master_nodes` sert **uniquement** au bootstrapping initial du cluster (premier démarrage). Une fois le cluster formé, cette configuration doit être retirée. La laisser peut causer des problèmes si le cluster est redémarré et un "split-brain" accidentel lors de futures maintenance.
</details>

---

## Question 10 : Réplication — Cluster vert

Un index a 3 primary shards et 1 replica par shard. Quel est le nombre minimum de nœuds pour que cet index soit en statut "vert" ?

A) 1  
B) 2  
C) 3  
D) 4  

<details>
<summary>Réponse</summary>

**Réponse : B**

Pour qu'un index soit vert, TOUTES les primary ET replica shards doivent être assignées. Si on a 3 primaires + 3 replicas = 6 shards au total, une replica ne peut pas être sur le même nœud que sa primary. Donc il faut au minimum **2 nœuds** (3 primaires sur l'un, 3 replicas sur l'autre).
</details>

---

## Question 11 : Aliases — Utilité principale

Quelle est la principale utilité des aliases dans OpenSearch ?

A) Changer le nombre de primary shards d'un index  
B) Effectuer un basculement d'index sans downtime lors d'un reindex  
C) Augmenter le nombre de replicas dynamiquement  
D) Améliorer les performances de recherche  

<details>
<summary>Réponse</summary>

**Réponse : B**

Les aliases permettent de pointer vers un index sous un nom virtuel. Pour reindexer sans interruption : créer `products-v2`, reindexer dedans, puis basculer l'alias atomiquement de `products-v1` vers `products-v2`. Les clients ne voient aucune interruption. Les aliases permettent aussi le filtrage (aliases filtrés).
</details>

---

## Question 12 : Diagnostic — Shards non assignés

Quelle API OpenSearch explique précisément pourquoi un shard n'est pas assigné à un nœud ?

A) `GET _cluster/health`  
B) `GET _cat/shards`  
C) `GET _cluster/allocation/explain`  
D) `GET _nodes/stats`  

<details>
<summary>Réponse</summary>

**Réponse : C**

`_cluster/allocation/explain` est l'API de diagnostic des shards non assignés. Elle indique la raison précise : disque plein, nœud absent, limite `max_shards_per_node` atteinte, contrainte de filtrage, etc. `_cat/shards` (B) montre l'état mais pas la cause.
</details>

---

## Question 13 : Snapshots — Nature

Qu'est-ce qu'un snapshot dans OpenSearch ?

A) Une copie complète et très coûteuse des données  
B) Un backup incrémental des segments Lucene  
C) Un export JSON de tous les documents  
D) Une archive ZIP des fichiers de configuration  

<details>
<summary>Réponse</summary>

**Réponse : B**

Les snapshots OpenSearch sont **incrémentiels** : seuls les segments Lucene modifiés depuis le dernier snapshot sont copiés. Le premier snapshot copie tout, les suivants uniquement les deltas. Ils sont bien plus efficaces qu'un backup complet. Les repositories supportés : filesystem, S3, Azure, GCS.
</details>

---

## Question 14 : ISM — État Hot

Dans une politique ISM (Index State Management), l'état `hot` correspond typiquement à quelle situation ?

A) L'index est en cours de suppression  
B) L'index est compressé (force_merge)  
C) L'index est actif, reçoit des écritures et des lectures fréquentes  
D) L'index est en lecture seule sur disque froid  

<details>
<summary>Réponse</summary>

**Réponse : C**

Dans le cycle de vie hot/warm/cold/delete : **hot** = données récentes, accès fréquent en lecture et écriture, stockage SSD rapide. **warm** = données moins récentes, lecture seulement. **cold** = données archivées, accès rare. **delete** = suppression automatique après la période de rétention.
</details>

---

## Question 15 : Sécurité — TLS Transport

Quelle couche TLS chiffre les communications entre nœuds dans un cluster OpenSearch ?

A) REST  
B) Transport  
C) Application  
D) HTTP  

<details>
<summary>Réponse</summary>

**Réponse : B**

La couche **Transport** (port 9300 par défaut) chiffre toutes les communications inter-nœuds : réplication de shards, état du cluster, forward de requêtes. La couche **REST** (port 9200) chiffre les communications entre clients (curl, SDK, Dashboards) et le cluster. Les deux sont configurables indépendamment.
</details>

---

## Question 16 : RBAC — Modèle

Sur quel modèle repose l'autorisation dans OpenSearch Security ?

A) Les adresses IP des clients  
B) Les rôles assignés aux utilisateurs ou groupes  
C) La configuration des nœuds  
D) Les index templates  

<details>
<summary>Réponse</summary>

**Réponse : B**

OpenSearch Security implémente le **RBAC** (Role-Based Access Control) : on définit des rôles avec des permissions (cluster + index), puis on assigne ces rôles à des utilisateurs ou des groupes backend (LDAP). Un utilisateur hérite des permissions de tous ses rôles.
</details>

---

## Question 17 : DLS — Mécanisme

Comment fonctionne le Document Level Security (DLS) dans OpenSearch ?

A) Il chiffre chaque document individuellement  
B) Il ajoute automatiquement un filtre de requête selon le rôle de l'utilisateur  
C) Il masque les noms des champs selon le rôle  
D) Il supprime les documents non autorisés de l'index  

<details>
<summary>Réponse</summary>

**Réponse : B**

Le DLS ajoute une clause `query` supplémentaire (un filtre) à chaque requête de l'utilisateur. Par exemple, un utilisateur avec DLS `{"term": {"region": "Paris"}}` ne verra que les documents où `region = "Paris"`. Les documents ne sont pas supprimés — ils existent mais sont filtrés à la requête.
</details>

---

## Question 18 : FLS — Capacité

Que peut faire le Field Level Security (FLS) dans OpenSearch ?

A) Chiffrer les valeurs des champs sensibles  
B) Masquer des champs spécifiques selon le rôle de l'utilisateur  
C) Changer le type d'un champ selon l'utilisateur  
D) Supprimer les champs de l'index de façon permanente  

<details>
<summary>Réponse</summary>

**Réponse : B**

Le FLS (Field Level Security) permet d'exclure des champs de la réponse selon le rôle. Par exemple, le rôle `analyst` peut voir les produits mais pas les champs `price` et `original_price`. On les préfixe avec `~` pour les exclure : `"fls": ["~price", "~original_price"]`. Les données sont toujours dans l'index — elles ne sont simplement pas retournées.
</details>

---

## Question 19 : Audit Logging — But principal

Quel est l'objectif principal de l'audit logging dans OpenSearch Security ?

A) Améliorer les performances de recherche  
B) Tracer les événements d'accès pour la conformité réglementaire (ex: RGPD)  
C) Gérer le cycle de vie des index  
D) Surveiller la santé des nœuds  

<details>
<summary>Réponse</summary>

**Réponse : B**

L'audit logging enregistre qui a accédé à quoi et quand : connexions réussies/échouées, requêtes accordées/refusées, opérations administratives. Catégories d'événements : `GRANTED_PRIVILEGES`, `FAILED_LOGIN`, `MISSING_PRIVILEGES`, `SSL_EXCEPTION`. Indispensable pour les environnements RGPD, PCI-DSS, HIPAA.
</details>

---

## Question 20 : Monitoring — Heap JVM

Une utilisation de la heap JVM à 85% dans un nœud OpenSearch indique :

A) Un fonctionnement normal  
B) Une action requise en urgence — risque d'OutOfMemoryError  
C) Une corruption de l'index  
D) Un rééquilibrage des shards en cours  

<details>
<summary>Réponse</summary>

**Réponse : B**

Au-delà de 75% de heap JVM, le risque d'OutOfMemoryError (OOM) augmente fortement, ce qui peut provoquer la mort du nœud. À 85%, c'est une urgence : activer le GC agressif, investiguer les requêtes lourdes, augmenter la heap ou réduire les charges. Seuils : < 75% = normal, 75-85% = surveillance, > 85% = action immédiate.
</details>

---

*Quiz Final — Formation OpenSearch 3.6 — Bonne chance !*
