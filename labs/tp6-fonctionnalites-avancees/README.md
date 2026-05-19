# TP6 — Ingest Pipelines

## Objectif
Maîtriser les ingest pipelines OpenSearch : créer, tester, gérer les erreurs et chaîner plusieurs pipelines.

## Prérequis
- TP5 terminé, index `products` avec 1000+ documents
- Cluster OpenSearch running sur http://localhost:9200

## Durée estimée
40 minutes

## Contexte (fil rouge)
Les données de notre catalogue e-commerce arrivent sales : catégories en majuscules, descriptions avec espaces parasites, prix sous forme de chaîne. On va transformer tout ça **avant** l'indexation, côté serveur, sans toucher au code applicatif.

---

### Exercice 1 : Créer un pipeline de normalisation
**Objectif** : Transformer automatiquement les documents à l'indexation.

**Instructions** :
1. Créer un pipeline `pipeline-normalisation` avec les processors :
   - `lowercase` sur le champ `category`
   - `trim` sur le champ `description`
   - `convert` sur le champ `price` → type `float`
2. Tester avec `_simulate` sur un document exemple (`category: "ELECTRONIQUE"`, `description: "  Ordi  "`, `price: "299.99"`)
3. Vérifier que le document simulé a bien `category: "electronique"`, `description: "Ordi"`, `price: 299.99`

**Indice** : `PUT /_ingest/pipeline/pipeline-normalisation`
**Vérification** : La réponse `_simulate` doit montrer le document transformé sans erreur.

---

### Exercice 2 : Ajouter un champ d'audit et gérer les erreurs
**Objectif** : Enrichir les documents et rendre le pipeline robuste en production.

**Instructions** :
1. Créer un pipeline `pipeline-enrichissement` avec les processors :
   - `set` pour ajouter `indexed_at` avec la valeur `{{{_ingest.timestamp}}}`
   - `remove` pour supprimer le champ `_tmp` avec `ignore_missing: true`
2. Ajouter un `on_failure` sur le processor `set` qui route les documents en erreur vers l'index `failed-products` (via `set` sur `_index`)
3. Indexer un produit réel avec `?pipeline=pipeline-enrichissement` et vérifier que `indexed_at` est présent

**Indice** : `PUT /products/_doc/1?pipeline=pipeline-enrichissement`
**Vérification** : `GET /products/_doc/1` doit montrer le champ `indexed_at`.

---

### Exercice 3 : Processor conditionnel
**Objectif** : Appliquer un processor uniquement sous condition (Painless).

**Instructions** :
1. Créer un pipeline `pipeline-segment` avec un processor `set` conditionnel :
   - Si `ctx.price != null && ctx.price > 500` → ajouter `segment: "premium"`
   - Sinon → ajouter `segment: "standard"`
2. Tester avec `_simulate` sur deux documents : un à `price: 799` et un à `price: 49`
3. Vérifier que chaque document reçoit le bon segment

**Indice** : `"if": "ctx.price != null && ctx.price > 500"` dans le processor
**Vérification** : Les deux documents simulés ont des valeurs `segment` différentes.

---

### Exercice 4 : Chaîner plusieurs pipelines
**Objectif** : Combiner des pipelines spécialisés en un pipeline maître via le processor `pipeline`.

**Contexte** : En production, on préfère des pipelines petits et réutilisables plutôt qu'un seul pipeline monolithique. Le processor `pipeline` permet d'en appeler un autre depuis un pipeline courant.

**Instructions** :
1. Les pipelines `pipeline-normalisation` et `pipeline-enrichissement` (créés aux exercices 1 et 2) sont déjà disponibles.
2. Créer un pipeline maître `pipeline-produits-complet` qui enchaîne les deux :
   - d'abord `pipeline-normalisation`
   - puis `pipeline-enrichissement`
3. Tester avec `_simulate` : un seul appel doit déclencher les deux pipelines en séquence.
4. Indexer un document avec `?pipeline=pipeline-produits-complet` et vérifier que toutes les transformations sont appliquées.

**Indice** : `{ "pipeline": { "name": "pipeline-normalisation" } }` comme processor
**Vérification** : Le document final doit avoir `category` en minuscules ET `indexed_at` présent.

---

## Vérification finale
- [ ] Pipeline `pipeline-normalisation` : lowercase + trim + convert testés via `_simulate`
- [ ] Pipeline `pipeline-enrichissement` : `indexed_at` présent sur le document indexé
- [ ] Processor conditionnel : deux documents avec segments différents
- [ ] Pipeline `pipeline-produits-complet` : enchaîne les deux pipelines en un seul appel

*Passez au [TP7 — Analyseur français](../tp7-analyseur/README.md)*
