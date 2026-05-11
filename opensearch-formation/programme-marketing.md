# Formation OpenSearch 3.6 — Programme

**Durée** : 3 jours | **Format** : Théorie & pratique  
**Public** : Développeurs, Data Engineers, DevOps  
**Prérequis** : Notions de base en REST API et JSON

---

## Jour 1 — Fondamentaux & Prise en main

**Matin**

- Introduction à OpenSearch : cas d'usage, positionnement, écosystème
- Installation et mise en route d'un cluster local
- Mappings et types de champs

*Atelier pratique : démarrer un cluster OpenSearch et créer ses premiers index avec des mappings structurés*

**Après-midi**

- API REST : indexation, opérations Create, Read, Update, Delete (CRUD)
- Bulk API
- Query Domain Specific Language (DSL)
- Pagination et filtres combinés

*Atelier pratique : indexer un catalogue de produits et construire une recherche avec filtres*

---

## Jour 2 — Sécurité & Architecture

**Matin**

- Sécurité : rôles et permissions, accès restreints aux champs et aux documents
- Fonctionnalités avancées : Ingest Pipelines, analyseurs et tokenizers

*Atelier pratique : configurer des profils d'accès et mettre en place un pipeline d'ingestion avec un analyseur personnalisé*

**Après-midi**

- Architecture cluster : internals Lucene, types de nœuds, haute disponibilité
- Sizing des shards, scalabilité et bonnes pratiques production
- Routage des données et optimisation des performances

*Atelier pratique : déployer un cluster multi-nœuds en haute disponibilité et observer l'impact du routage*

---

## Jour 3 — Agrégations, Dashboards & Cycle de vie

**Matin**

- Agrégations : métriques, buckets, imbrication
- Scoring et pertinence des résultats

*Atelier pratique : analyser un catalogue de données avec des agrégations avancées*

**Après-midi**

- OpenSearch Dashboards : visualisations, Kibana Query Language (KQL), construction de dashboards
- Gestion du cycle de vie de l'index : aliases, Index State Management (ISM), snapshots

*Atelier pratique : construire un dashboard e-commerce et automatiser la rotation des index*

---
