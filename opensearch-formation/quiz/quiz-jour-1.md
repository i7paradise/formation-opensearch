# Quiz — Jour 1 : Fondamentaux d'OpenSearch

**Instructions :** Pour chaque question, choisissez la réponse la plus appropriée parmi les 4 propositions.

---

## Question 1 : Architecture — Terminologie de base

Dans OpenSearch, quelle affirmation décrit correctement la hiérarchie des concepts ?

A) Un cluster contient des indexes, un index contient des shards, un shard contient des documents

B) Un nœud contient des clusters, un cluster contient des indexes, un index contient des documents

C) Un shard contient des nœuds, un nœud contient des indexes, un index contient des documents

D) Un cluster contient des nœuds, chaque nœud peut héberger des shards, chaque shard contient des documents Lucene

<details>
<summary>Réponse</summary>

**Réponse : D**

Explication : La hiérarchie correcte est : **Cluster → Nœuds → Index → Shards → Documents**. Un cluster est l'ensemble des nœuds. Chaque nœud héberge un sous-ensemble des shards (fragments de l'index). Chaque shard est un index Lucene autonome qui contient les documents. La réponse A est partiellement correcte mais passe sous silence le niveau nœud.

</details>

---

## Question 2 : Documents vs base de données relationnelle

Quelle correspondance est correcte entre OpenSearch et une base de données relationnelle SQL ?

A) Index = Colonne, Document = Ligne, Champ = Table

B) Index = Base de données, Document = Table, Champ = Ligne

C) Index = Table, Document = Ligne, Champ = Colonne

D) Index = Schéma, Document = Vue, Champ = Contrainte

<details>
<summary>Réponse</summary>

**Réponse : C**

Explication : L'analogie la plus utilisée est : **Index ≈ Table**, **Document ≈ Ligne (enregistrement)**, **Champ ≈ Colonne**. Cependant, OpenSearch est plus flexible qu'une table SQL : les documents d'un même index peuvent avoir des champs différents, et les champs sont typés dynamiquement. La notion de "base de données" se rapproche davantage du "cluster" ou de l'"instance OpenSearch".

</details>

---

## Question 3 : API CRUD — PUT vs POST pour l'indexation

Quelle est la différence fondamentale entre `PUT /products/_doc/1` et `POST /products/_doc` ?

A) `PUT` utilise le format JSON, `POST` utilise le format XML

B) `PUT` nécessite de spécifier l'ID du document, `POST` génère un ID aléatoire automatiquement

C) `PUT` crée uniquement, `POST` met à jour uniquement — ils ne peuvent pas faire les deux

D) `PUT` indexe dans le shard primaire uniquement, `POST` indexe dans tous les shards

<details>
<summary>Réponse</summary>

**Réponse : B**

Explication : La différence principale est la gestion de l'identifiant. `PUT /products/_doc/1` impose l'ID `1` au document (création ou remplacement complet). `POST /products/_doc` laisse OpenSearch générer un ID unique (UUID). Les deux opérations créent le document s'il n'existe pas et le remplacent s'il existe déjà. Pour une mise à jour partielle, on utilise `POST /products/_update/1`.

</details>

---

## Question 4 : Mapping — Types de champs `text` vs `keyword`

Un champ de type `text` et un champ de type `keyword` traitent-ils les données différemment ?

A) Non, les deux types stockent la valeur exacte et permettent la recherche exacte

B) Le type `text` est analysé (tokenisé, normalisé), le type `keyword` est stocké tel quel sans analyse

C) Le type `keyword` est analysé, le type `text` est stocké tel quel

D) La seule différence est la taille maximale : `text` supporte jusqu'à 32 000 caractères, `keyword` jusqu'à 256

<details>
<summary>Réponse</summary>

**Réponse : B**

Explication : C'est une distinction fondamentale en OpenSearch. Un champ `text` passe par la chaîne d'analyse (tokenizer + token filters) : le texte est découpé en tokens, mis en minuscules, les mots vides sont supprimés, etc. Cela permet la recherche en langage naturel (`match`). Un champ `keyword` est stocké tel quel, sans analyse : il permet la recherche exacte (`term`), les agrégations `terms`, et le tri. Pour les champs comme `category` ou `status`, utilisez `keyword`. Pour les champs de recherche plein texte comme `description`, utilisez `text`.

</details>

---

## Question 5 : Quand utiliser `keyword` vs `text` ?

Vous modélisez un catalogue de produits. Pour quel champ devriez-vous utiliser le type `keyword` plutôt que `text` ?

A) Le champ `description` contenant un texte long décrivant le produit

B) Le champ `name` sur lequel les utilisateurs font des recherches partielles

C) Le champ `status` prenant les valeurs `"en_stock"`, `"rupture"`, `"discontinué"`

D) Le champ `tags` contenant des phrases descriptives comme `"haute qualité"`

<details>
<summary>Réponse</summary>

**Réponse : C**

Explication : Le champ `status` avec des valeurs discrètes et fixes comme `"en_stock"` ou `"rupture"` doit être de type `keyword`. On n'a jamais besoin de faire une recherche floue sur ces valeurs — on cherche toujours la valeur exacte. De plus, on voudra probablement utiliser ce champ dans des agrégations (`terms` sur `status`). Les champs `description`, `name` et `tags` bénéficient de l'analyse pour la recherche en langage naturel, donc `text` est plus approprié (ou un mapping multi-champs `text` + `keyword`).

</details>

---

## Question 6 : Query DSL — `match` vs `term`

Quelle requête renvoie des documents contenant le mot "électronique" dans le champ `description`, quelle que soit la casse ?

A) `{ "term": { "description": "Électronique" } }`

B) `{ "match": { "description": "électronique" } }`

C) `{ "term": { "description.keyword": "électronique" } }`

D) `{ "exact": { "description": "électronique" } }`

<details>
<summary>Réponse</summary>

**Réponse : B**

Explication : La requête `match` est conçue pour les champs `text` analysés. Elle analyse le terme de recherche avec le même analyseur que celui utilisé à l'indexation, ce qui rend la recherche insensible à la casse et aux variations linguistiques. La requête `term` fait une recherche **exacte** et ne passe pas par l'analyseur — `term` sur un champ `text` ne fonctionne généralement pas comme attendu car les tokens stockés sont en minuscules. Pour une valeur exacte `"électronique"` sur un champ analysé `description`, utilisez `match`. Pour une recherche exacte sur `category.keyword` (non analysé), utilisez `term`.

</details>

---

## Question 7 : Bool Query — `filter` vs `must`

Vous voulez récupérer des produits de catégorie "Électronique" avec un prix inférieur à 500€. Quelle structure de requête est optimale en termes de performances ?

A) `{ "bool": { "must": [ { "term": { "category": "Électronique" } }, { "range": { "price": { "lt": 500 } } } ] } }`

B) `{ "bool": { "filter": [ { "term": { "category": "Électronique" } }, { "range": { "price": { "lt": 500 } } } ] } }`

C) `{ "bool": { "should": [ { "term": { "category": "Électronique" } }, { "range": { "price": { "lt": 500 } } } ] } }`

D) `{ "bool": { "must_not": [ { "term": { "category": "Électronique" } } ], "must": [ { "range": { "price": { "lt": 500 } } } ] } }`

<details>
<summary>Réponse</summary>

**Réponse : B**

Explication : Le contexte `filter` est plus performant que `must` pour les critères qui ne contribuent pas au score de pertinence. Les clauses `filter` sont **cachées** par OpenSearch — si le même filtre est appliqué plusieurs fois, le résultat est récupéré du cache sans recalcul. De plus, les clauses `filter` ne calculent pas de score BM25, ce qui économise du CPU. Le contexte `must` est utile quand le score de pertinence compte (ex. recherche textuelle). Ici, filtrer sur `category` et `price` est purement booléen — pas besoin de scorer ces conditions.

</details>

---

## Question 8 : Scoring BM25

Deux documents contiennent le mot "laptop". Le Document A est un court titre de 5 mots, le Document B est une longue description de 200 mots. Les deux contiennent "laptop" une seule fois. Lequel obtient le meilleur score BM25 ?

A) Document B, car il contient plus de contenu contextualisé

B) Document A, car le terme "laptop" représente une proportion plus élevée du document (field length normalization)

C) Les deux ont exactement le même score, car le terme n'apparaît qu'une fois dans chacun

D) Cela dépend du champ utilisé, pas de la longueur du document

<details>
<summary>Réponse</summary>

**Réponse : B**

Explication : BM25 intègre une **normalisation par la longueur du champ**. Un terme apparaissant dans un document court est considéré comme plus significatif que le même terme dans un document long. Intuitivement : si "laptop" est 1 mot sur 5, c'est 20% du contenu — très pertinent. Si "laptop" est 1 mot sur 200, c'est 0.5% — probablement une mention anecdotique. Les 3 facteurs de BM25 sont : (1) TF — fréquence du terme, (2) IDF — rareté du terme dans le corpus, (3) Field Length Norm — normalisation par la longueur du document.

</details>

---

## Question 9 : Mapping dynamique strict

Vous créez un index `produits_complet` avec `"dynamic": "strict"`. Que se passe-t-il si vous tentez d'indexer un document contenant un champ non défini dans le mapping ?

A) OpenSearch crée automatiquement le champ avec le type deviné à partir de la valeur

B) Le document est indexé sans le champ non reconnu (champ silencieusement ignoré)

C) OpenSearch retourne une erreur `strict_dynamic_mapping_exception` et rejette le document

D) Le document est mis en quarantaine dans un index `.rejected` dédié

<details>
<summary>Réponse</summary>

**Réponse : C**

Explication : Avec `"dynamic": "strict"`, OpenSearch rejette toute tentative d'indexer un champ non défini dans le mapping en levant une `strict_dynamic_mapping_exception`. C'est le comportement souhaité en production pour éviter les "mapping explosions" — situations où des champs imprévus s'accumulent automatiquement et finissent par saturer la mémoire. Avec `"dynamic": true` (défaut), le comportement serait A. Avec `"dynamic": false`, le comportement serait B.

</details>

---

## Question 10 : Bulk API — Bonnes pratiques

Parmi ces pratiques, laquelle est recommandée pour charger efficacement 50 000 documents dans OpenSearch ?

A) Utiliser 50 000 requêtes `PUT` individuelles avec un délai de 100 ms entre chaque

B) Utiliser le Bulk API avec `refresh_interval: -1` pendant le chargement, puis rétablir `1s` à la fin

C) Désactiver le cluster entier, copier les fichiers JSON sur disque, puis redémarrer

D) Utiliser `POST /index/_doc` avec un seul grand tableau JSON contenant les 50 000 documents

<details>
<summary>Réponse</summary>

**Réponse : B**

Explication : Le Bulk API (format NDJSON, action + document par paire de lignes) est la méthode recommandée pour les chargements massifs. Combiner avec `refresh_interval: -1` (désactiver le refresh automatique pendant le chargement) et `number_of_replicas: 0` (réactiver après) permet d'atteindre des performances 5 à 10 fois supérieures. La taille optimale par batch Bulk est entre 5 et 15 MB. Le flag `--data-binary` est obligatoire avec curl pour préserver les sauts de ligne du format NDJSON.

</details>
