# Quiz Jour 2 — Sécurité, Fonctionnalités Avancées & Cluster

> **Instructions** : 10 questions, 1 seule réponse correcte par question. Les réponses sont dans les blocs `<details>`.

---

## Question 1 : Ingest Pipelines — Processeurs

Quel processeur d'ingest pipeline permet d'extraire des données structurées depuis un texte non structuré à l'aide de patterns (comme les regex Grok) ?

A) `set`  
B) `grok`  
C) `trim`  
D) `remove`  

<details>
<summary>Réponse</summary>

**Réponse : B**

Le processeur `grok` utilise des patterns prédéfinis (similaires aux expressions régulières) pour analyser du texte non structuré et en extraire des champs typés. Il est particulièrement utile pour parser des logs applicatifs.

Exemple : `{ "grok": { "field": "message", "patterns": ["%{HTTPD_COMMONLOG}"] } }`
</details>

---

## Question 2 : Chaîne d'analyse — Ordre

Dans la chaîne d'analyse d'OpenSearch, quel composant s'applique en PREMIER sur le texte ?

A) Token Filter  
B) Tokenizer  
C) Char Filter  
D) Stemmer  

<details>
<summary>Réponse</summary>

**Réponse : C**

L'ordre est : **Char Filter → Tokenizer → Token Filters**

Les Char Filters s'appliquent en premier sur le texte brut (ex: `html_strip` supprime les balises HTML). Ensuite le Tokenizer découpe le texte en tokens. Enfin les Token Filters transforment les tokens individuels.
</details>

---

## Question 3 : Token Filters — Accents

Quel token filter convertit les caractères accentués en leur équivalent ASCII (ex: `é` → `e`, `ç` → `c`) ?

A) `lowercase`  
B) `stemmer`  
C) `stop`  
D) `asciifolding`  

<details>
<summary>Réponse</summary>

**Réponse : D**

Le filter `asciifolding` convertit les caractères Unicode en leur équivalent ASCII le plus proche. Grâce à lui, chercher "velo" trouve aussi "vélo" et vice versa. Indispensable pour les analyseurs de texte en français.
</details>

---

## Question 4 : Tokenizers — Autocomplétion

Quel tokenizer produit des tokens de longueur croissante à partir du début d'un mot, idéal pour l'autocomplétion préfixe ?

A) `standard`  
B) `whitespace`  
C) `edge_ngram`  
D) `keyword`  

<details>
<summary>Réponse</summary>

**Réponse : C**

Le tokenizer `edge_ngram` génère des tokens ancrés au début du mot. Pour "ordinateur" avec `min_gram: 2, max_gram: 10`, il produit : "or", "ord", "ordi", "ordin", "ordina", etc. Parfait pour l'autocomplétion.

Note : pour l'autocomplétion temps réel, le type `completion` est souvent préférable car il utilise une structure de données dédiée (FST).
</details>

---

## Question 5 : Completion Suggester — Type de champ

Quel type de champ OpenSearch doit-on utiliser pour implémenter un completion suggester performant ?

A) `text`  
B) `keyword`  
C) `completion`  
D) `search_as_you_type`  

<details>
<summary>Réponse</summary>

**Réponse : C**

Le type `completion` utilise une structure de données spécialisée (Finite State Transducer - FST) chargée en mémoire pour des suggestions ultra-rapides. Il doit être défini dans le mapping et les valeurs indexées explicitement.

`search_as_you_type` (D) est aussi valide mais utilise un mécanisme différent (n-grams sur plusieurs champs).
</details>

---

## Question 6 : Highlighting — Position dans la requête

Où place-t-on la clause `highlight` dans une requête OpenSearch ?

A) À l'intérieur de la clause `query`  
B) Au même niveau que `query`, en dehors  
C) Dans le mapping de l'index  
D) Dans les settings de l'index  

<details>
<summary>Réponse</summary>

**Réponse : B**

La clause `highlight` est un paramètre de niveau requête (au même niveau que `query`, `aggs`, `sort`). Elle ne modifie pas les résultats mais ajoute des extraits surlignés dans la clé `highlight` de chaque hit.

```json
{
  "query": { "match": { "name": "ordinateur" } },
  "highlight": { "fields": { "name": {} } }
}
```
</details>

---

## Question 7 : Recherche géographique

Quelle requête OpenSearch permet de trouver tous les documents dont un champ `geo_point` est dans un rayon donné autour d'un point GPS ?

A) `geo_bounding_box`  
B) `match`  
C) `geo_distance`  
D) `range`  

<details>
<summary>Réponse</summary>

**Réponse : C**

La requête `geo_distance` filtre les documents selon une distance euclidienne (en km, miles, etc.) autour d'un point central. La `geo_bounding_box` (A) filtre selon un rectangle géographique — utile pour les zones rectangulaires mais moins naturel qu'un rayon.
</details>

---

## Question 8 : Scoring — Contexte filter

Pour une condition de filtrage pur (sans impact sur le score de pertinence), quel contexte utilise-t-on dans un bool query ?

A) `must`  
B) `should`  
C) `filter`  
D) `must_not`  

<details>
<summary>Réponse</summary>

**Réponse : C**

Le contexte `filter` n'affecte pas le score `_score` et les résultats sont mis en cache automatiquement par OpenSearch. C'est plus performant que `must` pour les filtres booléens, de plage (range), ou sur des champs `keyword`. Règle : si la condition est oui/non (pas de pertinence), utilisez `filter`.
</details>

---

## Question 9 : Sécurité — Field Level Security (FLS)

Vous configurez un rôle OpenSearch avec la directive suivante : `"fls": ["~price", "~original_price"]`. Quel est l'effet de ce paramètre ?

A) Seuls les champs `price` et `original_price` sont retournés dans les résultats

B) Les champs `price` et `original_price` sont exclus des résultats pour les utilisateurs ayant ce rôle

C) L'accès à l'index est interdit si le document contient les champs `price` ou `original_price`

D) Les champs `price` et `original_price` sont chiffrés dans les réponses

<details>
<summary>Réponse</summary>

**Réponse : B**

Le préfixe `~` dans la liste FLS signifie **exclusion**. `"fls": ["~price", "~original_price"]` retire ces deux champs de toutes les réponses pour les utilisateurs ayant ce rôle. Les données sont toujours présentes dans l'index — elles sont simplement masquées à la restitution. Sans le préfixe `~`, la liste serait une liste blanche (seuls les champs listés seraient visibles). Le FLS est utile pour masquer des données sensibles (prix d'achat, marges) selon le profil de l'utilisateur.
</details>

---

## Question 10 : Cluster — Algorithme de routage

OpenSearch utilise la formule `hash(_id) % number_of_shards` pour router un document vers un shard. Pourquoi cela rend-il impossible la modification du nombre de primary shards sans reindex ?

A) Parce que `_id` est immutable une fois le document indexé

B) Parce que si N change, `hash(_id) % N` donnera un résultat différent — les documents existants ne seraient plus trouvables dans leur shard actuel

C) Parce que les shards ne peuvent pas recevoir de nouveaux documents une fois créés

D) Parce que le hash est calculé une seule fois et stocké dans le mapping de l'index

<details>
<summary>Réponse</summary>

**Réponse : B**

La formule de routage est déterministe et dépend du nombre total de shards N. Si un document avec `_id = "abc"` a été indexé quand N=5 et que `hash("abc") % 5 = 2` (shard 2), changer N à 6 donnerait `hash("abc") % 6 = 1` (shard 1) — OpenSearch chercherait dans le shard 1 et ne trouverait rien. C'est pourquoi il faut créer un nouvel index avec le bon nombre de shards et reindexer tous les documents. Le routing personnalisé (`?routing=valeur`) permet de forcer le shard cible, utile pour regrouper les documents d'une même catégorie.
</details>

---

*Quiz Jour 2 — Formation OpenSearch 3.6*
