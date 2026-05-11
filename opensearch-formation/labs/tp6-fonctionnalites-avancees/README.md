# TP6 — Fonctionnalités Avancées

## Objectif
Implémenter l'enrichissement des données et l'analyse linguistique française pour le moteur de recherche e-commerce.

> **Note** : Les exercices géolocalisation et completion suggester ont été déplacés dans des TPs optionnels dédiés.

## Prérequis
- TP5 terminé, index `products` avec 1000+ documents
- Cluster OpenSearch running sur http://localhost:9200

## Durée estimée
60 minutes

## Contexte (fil rouge)
Nous enrichissons notre moteur de recherche e-commerce : meilleure gestion du français, surlignage des termes et optimisation des pipelines d'indexation.

## Exercices

### Exercice 1 : Créer un Ingest Pipeline
**Objectif** : Transformer automatiquement les documents à l'indexation
**Instructions** :
1. Créer un pipeline `pipeline-produits` avec les processeurs : lowercase sur `category`, trim sur `description`, et set pour ajouter un champ `indexed_at` avec la valeur `{{_ingest.timestamp}}`
2. Tester le pipeline avec l'API `_simulate` sur un document exemple
3. Indexer un produit test en utilisant `?pipeline=pipeline-produits`

**Indice** : `PUT _ingest/pipeline/pipeline-produits`
**Vérification** : Le champ `category` doit être en minuscules et `indexed_at` présent

### Exercice 2 : Créer un Analyseur Français Personnalisé
**Objectif** : Améliorer la recherche full-text pour le français
**Instructions** :
1. Créer un nouvel index `products-v2` avec un analyseur custom `french_custom` incluant : tokenizer `standard`, token filters `lowercase`, `asciifolding`, `french_stop` (_french_), `french_stemmer` (language: french)
2. Ajouter le champ `name` avec l'analyseur `french_custom`
3. Tester avec `POST products-v2/_analyze` : "Vélos électriques d'entrée de gamme"

**Indice** : Définir l'analyseur dans `settings.analysis`
**Vérification** : Le token "vélos" doit produire le token "velo" (ou similaire après stemming)

### Exercice 3 : Réindexer avec le Nouvel Analyseur
**Objectif** : Migrer les données vers le nouvel index
**Instructions** :
1. Utiliser `POST _reindex` pour copier `products` vers `products-v2`
2. Vérifier le count : `GET products-v2/_count`
3. Tester la différence : chercher "vélo" dans `products` puis dans `products-v2`

**Indice** : `POST _reindex { "source": {"index": "products"}, "dest": {"index": "products-v2"} }`
**Vérification** : `products-v2` doit avoir le même nombre de documents que `products`

### Exercice 4 : Surlignage des Résultats
**Objectif** : Mettre en valeur les termes recherchés dans les résultats
**Instructions** :
1. Faire une recherche avec highlighting sur `name` et `description`
2. Utiliser `<mark>` et `</mark>` comme balises
3. Configurer `fragment_size: 150` pour les extraits

**Indice** : Clé `highlight` au même niveau que `query`
**Vérification** : Les résultats doivent contenir des champs `highlight.name` ou `highlight.description`

### Exercice 5 : Tri et Pagination avancée
**Objectif** : Implémenter une pagination efficace pour de gros volumes
**Instructions** :
1. Faire une recherche triée par prix décroissant avec `sort`
2. Tester la pagination avec `from` + `size`
3. Implémenter `search_after` pour la pagination profonde (sans limite des 10 000 premiers résultats)

**Indice** : `"sort": [{"price": {"order": "desc"}}]` + `"search_after": [valeur_du_dernier_doc]`
**Vérification** : Les résultats sont triés par prix et la pagination `search_after` fonctionne sur plusieurs pages

## TP Bonus (pour les plus rapides)
Implémenter "Voulez-vous dire ?" avec le term suggester :
- Utiliser `term` suggester sur le champ `name`
- Tester avec une faute d'orthographe : "ordenateur"
- Configurer `suggest_mode: "missing"` et `max_edits: 2`

## Vérification finale
- [ ] Pipeline créé et testé avec _simulate
- [ ] Index `products-v2` avec analyseur français
- [ ] Reindex effectué, counts identiques
- [ ] Highlighting présent dans les résultats
- [ ] Tri par prix et pagination search_after fonctionnels

*Passez au [TP7 — Installation cluster 3 nœuds](../tp7-cluster-3noeuds/README.md)*
