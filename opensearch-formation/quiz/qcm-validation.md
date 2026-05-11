# QCM — Validation de la formation OpenSearch

*7 questions — Niveau : débutant*

---

## Question 1 — Mapping : text vs keyword

Quelle affirmation décrit correctement la différence entre les types `text` et `keyword` ?

- A. `text` est analysé pour la recherche full-text ; `keyword` conserve la valeur exacte, non analysée
- B. `text` est réservé aux nombres ; `keyword` est réservé aux chaînes de caractères
- C. `text` et `keyword` sont identiques mais `keyword` est plus rapide
- D. `keyword` est analysé ; `text` ne l'est pas

---

## Question 2 — Mapping : dynamic strict

Que se passe-t-il lorsqu'on tente d'indexer un document contenant un champ absent du mapping, sur un index configuré avec `dynamic: strict` ?

- A. OpenSearch ajoute automatiquement le champ au mapping
- B. Le document est indexé sans le champ inconnu
- C. OpenSearch rejette le document avec une erreur `strict_dynamic_mapping_exception`
- D. OpenSearch convertit le champ vers le type le plus proche

---

## Question 3 — Mapping : multi-fields

Pourquoi utilise-t-on `name.keyword` plutôt que `name` pour trier des résultats ?

- A. `name` (type `text`) est analysé et ne peut pas être trié directement
- B. `name.keyword` est plus rapide car il est compressé
- C. `name` n'existe pas dans OpenSearch
- D. Le tri nécessite toujours un index séparé

---

## Question 4 — Query DSL : match vs term

Quelle requête utilise-t-on pour effectuer une **recherche full-text** sur le champ `description` ?

- A. `term`
- B. `range`
- C. `terms`
- D. `match`

---

## Question 5 — Architecture : split-brain

Quel est le nombre minimum de nœuds master-eligible recommandé pour éviter le split-brain dans un cluster OpenSearch ?

- A. 1
- B. 2
- C. 3
- D. 5

---

## Question 6 — Gestion des index : suppression

Quelle commande permet de supprimer un index nommé `products` dans OpenSearch ?

- A. `POST /products/_delete`
- B. `DELETE /products`
- C. `PUT /products/_close`
- D. `GET /products/_delete_by_query`

---

## Question 7 — Indexer plusieurs documents

Quelle est la bonne pratique pour indexer un catalogue de 5 000 produits dans OpenSearch ?

- A. Envoyer une requête `PUT /index/_doc/id` pour chaque produit individuellement
- B. Utiliser `POST /index/_bulk` avec un format NDJSON (ligne action + ligne document)
- C. Utiliser `POST /index/_update` avec une liste JSON de documents
- D. Utiliser `GET /index/_msearch` avec une liste de requêtes

---

## Corrigé

| # | Réponse | Explication |
|---|---------|-------------|
| 1 | **A** | `text` est tokenisé et analysé ; `keyword` stocke la valeur brute — indispensable pour les filtres, tris et agrégations |
| 2 | **C** | `dynamic: strict` protège contre les mapping explosions en rejetant tout champ non déclaré |
| 3 | **A** | Un champ `text` est découpé en tokens et ne peut pas être trié ; `name.keyword` conserve la valeur brute |
| 4 | **D** | `match` est la requête full-text de base ; elle analyse le texte avant la recherche |
| 5 | **C** | Avec 3 nœuds master-eligible, le quorum est de 2 — si un nœud tombe, les deux restants élisent un master sans risque de split-brain |
| 6 | **B** | `DELETE /products` supprime l'index ; `_close` le ferme sans le supprimer, `_delete_by_query` supprime des documents |
| 7 | **B** | Le Bulk API est 5 à 10× plus rapide qu'une indexation document par document ; format NDJSON obligatoire |
