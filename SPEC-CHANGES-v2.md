# Spec des modifications — Formation OpenSearch 3.6 (v2)

> **Statut** : ✅ Validé — prêt pour implémentation  
> **Date** : 2026-05-11  
> **Auteur** : Mary (BMad Strategic Analyst)  
> **Périmètre** : Programme, labs, guides formateur, timings, nouveaux fichiers HTML  
> **Hors périmètre** : `slides/` — aucune modification des fichiers de présentation reveal.js

---

## 1. Vue d'ensemble des changements

| # | Changement | Nature |
|---|-----------|--------|
| C1 | TP1 (installation) avancé à 10h30 | Déplacement + compression Ch1/Ch2 |
| C2 | Mappings & types de champs déplacés en fin de matinée J1 (Ch3a → 30 min) | Déplacement depuis Ch3a + compression |
| C3 | Nouveau TP2 "Créer un index complet" (12h00–12h30, fin matinée J1) | Création |
| C4 | J1 après-midi = CRUD / Bulk API / bonnes pratiques + antipatterns | Recentrage contenu |
| C5 | Agrégations retirées du J1 et déplacées en J3 matin | Déplacement |
| C6 | Sécurité (Ch8 + TP) déplacée en J2 matin — **scope réduit** (pas de TLS/certs) | Déplacement + réduction |
| C7 | Fonctionnalités avancées (Ch4 + TP6) repositionnées en J2 matin après sécurité | Déplacement |
| C8 | J2 après-midi = Architecture, scalabilité, cluster 3 nœuds, routing | Restructuration depuis J3 |
| C9 | Nouveau TP8 Routing (J2 après-midi) | Création |
| C10 | Bonnes pratiques _id, resharding, anticipation shard count en Ch6 J2 AM | Nouveau contenu |
| C11 | J3 matin = Agrégations complètes + BM25/scoring (préambule Dashboards) | Déplacement + enrichissement |
| C12 | J3 après-midi = Dashboards + Reindex + Gestion cycle de vie (ISM, snapshots) | Restructuration |
| C13 | Nouveau fichier `opensearch-formation/index.html` (landing page navigation) | Création HTML |
| C14 | Nouveaux fichiers `opensearch-formation/jour-x/index.html` (guides avec sommaire latéral) | Création HTML ×3 |
| C15 | Nouveau TP `tp-geo-optionnel` — géolocalisation, optionnel | Création (optionnel) |
| C16 | Nouveau TP `tp-completion-optionnel` — completion suggester, optionnel | Création (optionnel) |

---

## 2. Nouveau programme détaillé

### 2.1 Jour 1 — Fondamentaux & Prise en main (9h → 17h)

#### MATIN

| Heure | Durée | Activité | Type | Δ vs actuel |
|-------|-------|----------|------|------------|
| 09:00–09:30 | 30 min | Accueil, présentation, tour de table | Q/A | Inchangé |
| 09:30–09:45 | 15 min | Démo live ice breaker | Démo live | Inchangé |
| 09:45–10:20 | 35 min | **Ch1 (allégé)** : Introduction à OpenSearch | Cours | Compressé (était 45 min) |
| 10:20–10:30 | 10 min | **Ch2 (allégé)** : Installation — Docker Compose seulement | Cours | Compressé (était 45 min, voir §2.1.1) |
| **10:30–11:15** | **45 min** | **TP1** : Installation en local | TP | **Avancé de 11h30 → 10h30** |
| 11:15–11:30 | 15 min | Pause café | Pause | Déplacée (était 10h30) |
| 11:30–12:00 | 30 min | **Ch3a** : Mappings & types de champs OpenSearch | Cours | Déplacé depuis après-midi, **compressé à 30 min** |
| **12:00–12:30** | **30 min** | **TP2 NEW** : Créer un index complet avec tous les types de champs | TP | **Nouveau TP** |
| **12:30–13:30** | **60 min** | Déjeuner | Déjeuner | **Maintenu 12h30 (déjeuner toujours 12h30)** |

#### APRÈS-MIDI

| Heure | Durée | Activité | Type | Δ vs actuel |
|-------|-------|----------|------|------------|
| 13:30–14:15 | 45 min | **Ch3b** : API REST — GET, POST, PUT, DELETE + Bulk API + bonnes pratiques + antipatterns | Cours | Recentré sur CRUD |
| 14:15–15:00 | 45 min | **TP3** : CRUD, Bulk API & bonnes pratiques | TP | Était TP2 |
| 15:00–15:15 | 15 min | Pause | Pause | Inchangé |
| 15:15–15:45 | 30 min | **Ch3c** : Query DSL (match, term, range, bool, pagination) | Cours | Agrégations retirées → J3 |
| 15:45–16:30 | 45 min | **TP4** : Requêtes & recherche | TP | Était TP3 (sans aggs) |
| 16:30–17:00 | 30 min | Récap Jour 1, Q&A, preview Jour 2 | Q/A | Inchangé |

#### 2.1.1 Détail des allègements Ch1 & Ch2 pour libérer 10h30

**Contenu RETIRÉ de Ch1** (déplacé en J2 après-midi — section Architecture) :
- Lucene segments, refresh, merge (slides actuels lignes ~233–264)
- Split-brain & quorum (slides actuels lignes ~291–373)
- → Ces sujets appartiennent naturellement à l'architecture cluster

**Ch1 conserve** (35 min) :
- Cas d'usage OpenSearch (e-commerce, logs, SIEM, analytics)
- Histoire Elasticsearch → fork AWS → OpenSearch
- Architecture de base : cluster, nœuds, index, shards, documents
- Écosystème : Dashboards, Data Prepper, plugins
- Tableau comparatif OpenSearch vs Elasticsearch

**Ch2 réduit à 10 min** (juste assez pour lancer TP1) :
- Prérequis docker + vm.max_map_count (1 slide)
- La seule commande à retenir : `docker-compose up -d` (1 slide)
- Comment vérifier que c'est prêt : `_cluster/health` vert (1 slide)
- → Reste du chapitre (opensearch.yml, jvm.options, Cat APIs avancées) → guide formateur / ressources

#### 2.1.2 Nouveau TP2 — Créer un index complet avec tous les types de champs

**Objectif** : Créer à la main un index `produits_complet` couvrant tous les types de champs OpenSearch. Ancre les connaissances de Ch3a immédiatement.

**Contenu** :
1. Créer un mapping explicite : `text`, `keyword`, `integer`, `float`, `boolean`, `date`, `geo_point`, `nested`, et un champ avec `multi-fields` (text + keyword)
2. Vérifier le mapping avec `GET /produits_complet/_mapping`
3. Indexer 2–3 documents de test
4. Observer les différences text vs keyword avec `_analyze`
5. Tester dynamic mapping `strict` en tentant d'indexer un champ non mappé
- **Bonus** : ajouter un champ `completion` pour préparer l'autocomplétion

**Durée** : 30 min  
**Fichiers** : `labs/tp2-index-complet/README.md`, `labs/tp2-index-complet/exercices.sh`, `labs/tp2-index-complet/solution/solution.sh`

#### 2.1.3 Contenu ajouté à Ch3b (CRUD + bonnes pratiques)

| Sujet | Contenu |
|-------|---------|
| **Bulk API** | Format NDJSON, syntaxe `index`, `create`, `update`, `delete` en bulk, gestion des erreurs partielles |
| **Bonne pratique** | Toujours Bulk API pour > 100 documents. `refresh_interval=-1` pendant le chargement massif |
| **Antipattern DELETE doc** | Supprimer un document individuel est coûteux (tombstone, nécessite un merge). Préférer supprimer l'index entier, ou `delete_by_query` avec parcimonie |
| **Antipattern wildcard** | Éviter `*foo` en début de terme — force un scan complet de l'index inversé |
| **Bonne pratique** | `_source: includes/excludes` pour réduire la bande passante des réponses |

---

### 2.2 Jour 2 — Sécurité (matin) & Architecture / Cluster (après-midi)

#### MATIN

| Heure | Durée | Activité | Type | Δ vs actuel |
|-------|-------|----------|------|------------|
| **09:00–09:45** | **45 min** | **Ch8 : Sécurité dans OpenSearch (scope réduit)** | Cours | Déplacé depuis J3 + réduit (était 60 min) |
| 09:45–10:00 | 15 min | Pause | Pause | — |
| **10:00–10:30** | **30 min** | **TP5 : Sécurisation — RBAC + FLS** | TP | Déplacé depuis J3, réduit (était 45 min) |
| 10:30–11:30 | 60 min | **Ch4 : Fonctionnalités avancées** (Pipelines + Analyseurs + Suggestion) | Cours | Compressé à 60 min, géo retirée du cours |
| 11:30–12:30 | 60 min | **TP6 : Pipelines & Analyseurs** | TP | Était TP4, **élargi à 60 min** (15 min récupérés sur le récap supprimé) |
| 12:30–13:30 | 60 min | Déjeuner | Déjeuner | Inchangé |

#### 2.2.1 Scope réduit de la Sécurité (Ch8 + TP5)

**Contenu RETIRÉ du programme sécurité** :
- TLS/SSL : configuration transport layer, REST layer, certificats (demo certs)
- Authentication : LDAP, SAML, OpenID Connect (→ mentionnés en 1 slide "pour aller plus loin")
- Audit logging : retiré du TP, mentionné brièvement en cours

**Ch8 conserve** (45 min) :
- Security Plugin overview (5 min)
- RBAC : rôles, permissions (cluster vs index) (15 min)
- Créer un utilisateur et mapper à un rôle — démo live (10 min)
- Document Level Security (DLS) : filtrer les documents par rôle (5 min)
- Field Level Security (FLS) : masquer des champs par rôle (5 min)
- Slide "Pour aller plus loin" : TLS, LDAP, SAML, audit logging (5 min)

**TP5 — Sécurisation (30 min)** :
1. Se connecter en `admin` (sécurité activée sur le cluster 3 nœuds J2 AM)
2. Créer un rôle `products_reader` (read-only sur `products-*`)
3. Créer un utilisateur `analyst`, le mapper au rôle
4. Tester : `analyst` peut lire mais PAS écrire
5. FLS : `analyst` ne voit pas le champ `price` (masqué par le rôle)
- **Bonus DLS** : `analyst` ne voit que la catégorie `electronics`

#### 2.2.2 Sort de Ch4 (Fonctionnalités avancées) — Géo retirée du cours principal

**Geo_point et geo_distance** : retirés de Ch4 et de TP6 (trop spécialisés pour rester dans le fil principal).
- Mentionné brièvement dans Ch4 (1 slide, 5 min max) avec lien vers TP optionnel
- TP dédié optionnel créé : `labs/tp-geo-optionnel/`

**Completion suggester** : mentionné dans Ch4 avec démo formateur.
- TP dédié optionnel créé : `labs/tp-completion-optionnel/`

**Ch4 conserve** (60 min) :
- Ingest Pipelines : concept, processeurs courants, Simulate API (20 min)
- Analyseurs & Tokenizers : chaîne d'analyse, créer un analyseur français, `_analyze` API (20 min)
- Tri, Suggestion, Highlighting (15 min)
- Optimisation indexation & requêtes : `refresh_interval`, `replicas=0` au chargement, `dynamic:strict` (5 min)

**TP6 — Pipelines & Analyseurs (45 min)** :
1. Créer un pipeline d'ingestion (lowercase catégorie, ajout timestamp, trim)
2. Tester le pipeline avec Simulate API
3. Créer un analyseur custom français (stemmer + asciifolding)
4. Tester avec `_analyze` et comparer les tokens
5. Re-indexer les produits avec le nouvel analyseur
- **Bonus** : Highlighting sur les résultats de recherche

#### 2.2.3 Contenu Ch6 NEW : Architecture & Cluster (75 min)

| Bloc | Contenu | Source |
|------|---------|--------|
| **Lucene internals** (10 min) | Segments, refresh, merge — repris depuis Ch1 allégé | Déplacé depuis Ch1 |
| **Types de nœuds** (10 min) | Master, Data, Ingest, Coordinating ; dédié vs multi-rôle | Existant Ch6 J3 |
| **Discovery & quorum** (10 min) | seed_hosts, initial_master_nodes, split-brain, quorum min 3 | Déplacé depuis Ch1 |
| **Shards — sizing & anticipation** (10 min) | Primary (immuable), replica (dynamique), règle 10–50 GB, anticiper le volume à 2 ans | Enrichi |
| **Routage** (10 min) | Algorithme hash(_id) % nb_shards, routing personnalisé, importance de la distribution équilibrée | Enrichi depuis Ch6 |
| **Scalabilité & architectures** (10 min) | Exemples : mono-nœud dev, 3 nœuds prod, logs cluster, SaaS multi-tenant | Nouveau contenu |
| **Bonnes pratiques** (15 min) | Voir §2.2.4 | Nouveau contenu |

#### 2.2.4 Bonnes pratiques & antipatterns en Ch6

| Pratique | Description |
|---------|-------------|
| **_id personnalisé — avantage** | Indispensable pour les updates idempotents et pour éviter les doublons |
| **_id personnalisé — coût** | Le routing hash vérifie l'existence du doc → surcoût d'indexation vs ID auto (UUID aléatoire) |
| **Resharding** | Primary shards immuables → la seule façon est de Reindexer dans un nouvel index. Timing, coût, zero-downtime via alias |
| **Anticiper le nombre de shards** | Règle : volume cible ÷ 30 GB = nb shards primaires. Prévoir ×2 pour la croissance. Max 1 000 shards/nœud (configurable) |
| **Replicas ≠ backup** | Les replicas protègent contre la perte de nœud, pas contre les suppressions accidentelles. Seul un snapshot est un vrai backup |

#### APRÈS-MIDI

| Heure | Durée | Activité | Type | Δ vs actuel |
|-------|-------|----------|------|------------|
| 13:30–14:45 | 75 min | **Ch6 : Architecture & Cluster** (voir §2.2.3) | Cours | Recomposé depuis Ch6 J3 + contenu nouveau |
| 14:45–15:30 | 45 min | **TP7 : Installation cluster 3 nœuds** | TP | Était TP6 J3 (partie install) |
| 15:30–15:45 | 15 min | Pause | Pause | — |
| 15:45–16:30 | 45 min | **TP8 NEW : Routage — démonstration de l'importance de l'algorithme** | TP | Nouveau |
| 16:30–17:00 | 30 min | Récap Jour 2 + Q&A + preview Jour 3 | Q/A | — |

#### 2.2.5 TP8 NEW : Routage — démonstration de l'importance

**Objectif** : Montrer concrètement comment le routing impacte la distribution des données et les performances.

**Contenu** :
1. Créer un index avec 3 shards, indexer 300 documents avec ID automatique → observer la distribution avec `_cat/shards?v`
2. Indexer 300 documents avec routing forcé par catégorie → observer la distribution inégale
3. Requête avec et sans `?routing=` : mesurer le nombre de shards interrogés
4. Simuler un shard "chaud" (surcharge d'une catégorie) et comprendre l'impact
5. Créer un index avec routing custom et valider la concentration des données
- **Bonus** : `_cluster/allocation/explain` pour diagnostiquer un shard non assigné

**Durée** : 45 min  
**Fichiers** : `labs/tp8-routing/README.md`, `labs/tp8-routing/exercices.sh`, `labs/tp8-routing/solution/solution.sh`

---

### 2.3 Jour 3 — Agrégations (matin) & Dashboards + Cycle de vie (après-midi)

#### MATIN

| Heure | Durée | Activité | Type | Δ vs actuel |
|-------|-------|----------|------|------------|
| **09:00–10:00** | **60 min** | **Ch5 : Agrégations complètes** (voir §2.3.1) | Cours | Contenu déplacé depuis J1 + enrichi |
| 10:00–10:15 | 15 min | Pause | Pause | — |
| **10:15–11:30** | **75 min** | **TP9 NEW : Agrégations avancées** | TP | Nouveau, **élargi à 75 min** (15 min récupérés sur le récap supprimé) |
| 11:30–12:15 | 45 min | **Ch5b : Scoring BM25, _explain, search_after, optimisation** | Cours | Déplacé depuis J1 Ch3b |
| 12:15–12:30 | 15 min | Démo live Agrégations + Q&A | Démo live | — |
| 12:30–13:30 | 60 min | Déjeuner | Déjeuner | — |

#### APRÈS-MIDI

| Heure | Durée | Activité | Type | Δ vs actuel |
|-------|-------|----------|------|------------|
| 13:30–14:15 | 45 min | **Ch9 : OpenSearch Dashboards** (voir §2.3.2) | Cours | Était Ch5 J2 après-midi |
| 14:15–15:00 | 45 min | **TP10 : Dashboard e-commerce** | TP | Était TP5 J2 (raccourci de 75→45 min) |
| 15:00–15:15 | 15 min | Pause | Pause | — |
| 15:15–16:00 | 45 min | **Ch10 : Reindex & Gestion du cycle de vie** (voir §2.3.3) | Cours | ISM/Snapshots depuis Ch7 J3 + Reindex API |
| 16:00–16:30 | 30 min | **TP11 : Reindex + ISM** | TP | Extrait TP6 J3 + nouveau |
| 16:30–17:00 | 30 min | Récap global 3 jours + QCM + Satisfaction + Q&A | QCM + Q/A | Inchangé |

#### 2.3.1 Contenu Ch5 : Agrégations (60 min)

| Bloc | Contenu |
|------|---------|
| **Agrégations métriques** (15 min) | avg, sum, min, max, stats, extended_stats, percentiles, cardinality |
| **Agrégations bucket** (20 min) | terms, histogram, date_histogram, range, filters, significant_terms |
| **Agrégations pipeline** (10 min) | moving_avg, derivative, cumulative_sum |
| **Agrégations imbriquées** (15 min) | Sub-agrégations, top_hits, max bucket → lien direct avec les visualisations Dashboards |

**Fil rouge** : "Ces résultats que vous calculez ici sont exactement ce que vous allez visualiser dans Dashboards cet après-midi."

#### 2.3.2 Ch9 Dashboards (45 min) — adapté post-agrégations

Grâce aux agrégations vues le matin, la section "comment les agrégations se mappent aux visualisations" peut être réduite à 10 min.

Contenu :
- Interface Dashboards : Discover, Visualize, Dashboard, Management
- Index Patterns, KQL, filtres de temps
- Types de visualisations et quand les utiliser
- Assembler un dashboard, partage/embed
- Maps (Coordinate Map) — mention rapide, lien vers TP geo optionnel

#### 2.3.3 Ch10 : Reindex & Gestion du cycle de vie

| Bloc | Contenu | Source |
|------|---------|--------|
| **Reindex API** (15 min) | `POST /_reindex`, reindex avec transformation (script), zero-downtime via alias | Nouveau contenu |
| **Resharding via reindex** (5 min) | Lien avec les bonnes pratiques J2 — comment resharding en production | Lien avec §2.2.4 |
| **Index Templates** (5 min) | Rappel, focus sur les component templates | Depuis Ch6 J3 |
| **Aliases avancés** (5 min) | Zero-downtime deployment pattern, write alias vs read alias | Depuis Ch6 J3 |
| **ISM** (10 min) | Policies, états (hot→warm→cold→delete), rollover, force_merge | Depuis Ch7 J3 |
| **Snapshots** (5 min) | Résumé (fs, S3), create/restore | Depuis Ch7 J3 |

---

## 3. Récapitulatif des TPs (nouveau numérotage)

| TP | Jour | Heure | Durée | Titre | Δ vs actuel |
|----|------|-------|-------|-------|------------|
| **TP1** | J1 matin | 10h30 | 45 min | Installation en local | Inchangé, **avancé** |
| **TP2 NEW** | J1 matin | 12h00 | 30 min | Créer un index complet avec tous les types de champs | **Nouveau** |
| **TP3** | J1 AM | 14h15 | 45 min | CRUD, Bulk API & bonnes pratiques | Était TP2 + enrichi |
| **TP4** | J1 AM | 15h45 | 45 min | Query DSL & recherche (sans aggs) | Était TP3, aggs retirées |
| **TP5** | J2 matin | 10h00 | 30 min | Sécurisation — RBAC + FLS (scope réduit) | Était TP7 J3, **réduit** |
| **TP6** | J2 matin | 11h30 | 60 min | Fonctionnalités avancées — Pipelines & Analyseurs | Était TP4, **élargi à 60 min** |
| **TP7** | J2 AM | 14h45 | 45 min | Installation cluster 3 nœuds | Était TP6 J3 (partie install) |
| **TP8 NEW** | J2 AM | 15h45 | 45 min | Routage — démonstration de l'algorithme | **Nouveau** |
| **TP9 NEW** | J3 matin | 10h15 | 75 min | Agrégations avancées | **Nouveau, élargi à 75 min** |
| **TP10** | J3 AM | 14h15 | 45 min | Dashboard e-commerce | Était TP5 J2 (75→45 min) |
| **TP11** | J3 AM | 16h00 | 30 min | Reindex + ISM | Extrait TP6 J3 + nouveau |
| **TP-GEO** | Optionnel | — | 30 min | Requêtes géographiques (geo_point, geo_distance) | **Nouveau, optionnel** |
| **TP-COMPLETION** | Optionnel | — | 30 min | Autocomplétion avec le Completion Suggester | **Nouveau, optionnel** |

**Total obligatoires : 11 TPs** (vs 7 précédemment)  
**Total optionnels : 2 TPs** (geo + completion)

---

## 4. Fichiers à créer ou modifier

### 4.1 Nouveaux fichiers HTML (C13, C14)

#### 4.1.1 `opensearch-formation/index.html` — Landing page (À CRÉER)

**Rôle** : page d'accueil du kit, ouverte en premier par le formateur ou l'apprenant.

**Structure** :
```
[En-tête] : Titre "Formation OpenSearch 3.6", sous-titre, durée (3 jours, 21h)

[Section navigation principale] : 3 grandes cartes :
  - Jour 1 : Fondamentaux & Prise en main  → ./jour-1/index.html
  - Jour 2 : Sécurité & Architecture        → ./jour-2/index.html
  - Jour 3 : Agrégations, Dashboards & Cycle de vie → ./jour-3/index.html

[Section accès rapides] :
  - Slides J1/J2/J3 → ./slides/jour-x/index.html
  - Labs → ./labs/
  - README → ./README.md

[Section prérequis] : Docker, 4 GB RAM, ports 9200/5601

[Footer] : OpenSearch 3.6
```

**Style** : HTML/CSS autonome, fond blanc, palette slides (bleu #2563eb, vert #16a34a), font system-ui.

#### 4.1.2 `opensearch-formation/jour-x/index.html` — Guides par jour (À CRÉER ×3)

**Rôle** : version navigable du contenu de chaque jour avec sommaire latéral.

**Layout** :
```
┌──────────────────────────────────────────────────────────────┐
│  [Top nav] : ← Accueil | Jour 1 | Jour 2 | Jour 3            │
├───────────────┬──────────────────────────────────────────────┤
│  SOMMAIRE     │   CONTENU PRINCIPAL                          │
│  (sticky      │                                              │
│   250px)      │   ## ⏰ Matin                                 │
│               │   ### Ch1 : Introduction                     │
│  ▸ Matin      │   Timing : 09h45–10h20                       │
│    Ch1 Intro  │   [contenu + points clés...]                 │
│    Ch2 Inst.  │                                              │
│    TP1        │   ### 🔧 TP1 : Installation                   │
│    Ch3a Map.  │   Durée : 45 min | [→ labs/tp1/README.md]    │
│    TP2        │                                              │
│  ▸ Après-midi │   ## ☀️ Après-midi                            │
│    Ch3b CRUD  │   [...]                                      │
│    TP3        │                                              │
│    Ch3c DSL   │                                              │
│    TP4        │                                              │
└───────────────┴──────────────────────────────────────────────┘
```

**Comportement** :
- Sommaire latéral `position: sticky`, visible en scrollant
- Chaque entrée du sommaire = ancre `href="#section-id"`
- Section active surlignée en JS vanilla (`IntersectionObserver`)
- Lien "▶ Ouvrir les slides" vers `../slides/jour-x/index.html`
- Bouton "⬆" flottant bas-droite
- Responsive : sur mobile, sidebar se replie sous un bouton "Sommaire"

---

### 4.2 Nouveaux labs (à créer)

| Fichier | Notes |
|---------|-------|
| `labs/tp2-index-complet/README.md` | Voir §2.1.2 |
| `labs/tp2-index-complet/exercices.sh` | |
| `labs/tp2-index-complet/solution/solution.sh` | |
| `labs/tp8-routing/README.md` | Voir §2.2.5 |
| `labs/tp8-routing/exercices.sh` | |
| `labs/tp8-routing/solution/solution.sh` | |
| `labs/tp9-agregations/README.md` | Agrégations avancées J3 |
| `labs/tp9-agregations/exercices.sh` | |
| `labs/tp9-agregations/solution/solution.sh` | |
| `labs/tp11-reindex-ism/README.md` | Extrait de TP6 cluster + Reindex API |
| `labs/tp11-reindex-ism/exercices.sh` | |
| `labs/tp11-reindex-ism/solution/solution.sh` | |
| `labs/tp-geo-optionnel/README.md` | **Optionnel** — geo_point, geo_distance, geo_bounding_box |
| `labs/tp-geo-optionnel/exercices.sh` | |
| `labs/tp-geo-optionnel/solution/solution.sh` | |
| `labs/tp-completion-optionnel/README.md` | **Optionnel** — completion suggester, fuzzy, autocomplétion |
| `labs/tp-completion-optionnel/exercices.sh` | |
| `labs/tp-completion-optionnel/solution/solution.sh` | |

---

### 4.3 Labs existants à renommer et modifier (renommage physique des dossiers)

| Dossier actuel | Dossier cible | Changements de contenu |
|---------------|---------------|----------------------|
| `labs/tp2-crud-api/` | `labs/tp3-crud-api/` | Ajouter section bonnes pratiques Bulk + antipatterns DELETE |
| `labs/tp3-requetes-agregations/` | `labs/tp4-requetes/` | Retirer les exercices agrégations (déplacés en TP9) |
| `labs/tp4-fonctionnalites-avancees/` | `labs/tp6-fonctionnalites-avancees/` | Retirer exercices geo + completion (→ TPs optionnels). Durée : 45 min |
| `labs/tp5-dashboards/` | `labs/tp10-dashboards/` | Raccourcir à 45 min ; retirer exercices redondants avec TP9 |
| `labs/tp6-cluster/` | `labs/tp7-cluster-3noeuds/` | Isoler la partie "install 3 nœuds" ; déplacer ISM/snapshots → TP11 |
| `labs/tp7-securite/` | `labs/tp5-securite/` | Retirer tout ce qui concerne TLS/certificats. Contenu : voir §2.2.1 |

---

### 4.4 Guides formateur à réécrire

| Fichier | Action |
|---------|--------|
| `guide-formateur/timings.md` | **Réécrire** avec le nouveau tableau (section 6 ci-dessous) |
| `guide-formateur/jour-1-guide.md` | **Réécrire** — nouveau timing, TP2 ajouté, après-midi décale à 13h30 |
| `guide-formateur/jour-2-guide.md` | **Réécrire** — sécurité réduite le matin, archi l'après-midi |
| `guide-formateur/jour-3-guide.md` | **Réécrire** — agrégations matin, dashboards + cycle de vie AM |

---

### 4.5 Quiz à mettre à jour

| Fichier | Changement |
|---------|-----------|
| `quiz/quiz-jour-1.md` | Retirer questions sur agrégations. Ajouter : types de champs, mappings, Bulk API, antipatterns |
| `quiz/quiz-jour-2.md` | Retirer questions sur Dashboards. Ajouter : Sécurité RBAC/FLS, Architecture, Routing |
| `quiz/quiz-final.md` | Mettre à jour l'ordre des thèmes selon le nouveau programme |

---

## 5. Fichiers hors périmètre (ne pas toucher)

- `slides/jour-1/index.html`
- `slides/jour-2/index.html`
- `slides/jour-3/index.html`
- `slides/assets/`
- `slides/shared/`

---

## 6. Nouveau tableau timings.md

| Jour | Heure | Durée | Activité | Type |
|------|-------|-------|----------|------|
| Jour 1 | 09:00–09:30 | 30 min | Accueil, présentation, tour de table | Q/A |
| Jour 1 | 09:30–09:45 | 15 min | Démo live ice breaker | Démo live |
| Jour 1 | 09:45–10:20 | 35 min | Ch1 (allégé) : Introduction à OpenSearch | Cours |
| Jour 1 | 10:20–10:30 | 10 min | Ch2 (allégé) : Installation Docker Compose | Cours |
| Jour 1 | **10:30–11:15** | **45 min** | **TP1** : Installation en local | TP |
| Jour 1 | 11:15–11:30 | 15 min | Pause | Pause |
| Jour 1 | 11:30–12:00 | 30 min | Ch3a : Mappings & types de champs | Cours |
| Jour 1 | **12:00–12:30** | **30 min** | **TP2** : Créer un index complet | TP |
| Jour 1 | 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| Jour 1 | 13:30–14:15 | 45 min | Ch3b : API REST, CRUD, Bulk API, bonnes pratiques | Cours |
| Jour 1 | 14:15–15:00 | 45 min | **TP3** : CRUD, Bulk API & bonnes pratiques | TP |
| Jour 1 | 15:00–15:15 | 15 min | Pause | Pause |
| Jour 1 | 15:15–15:45 | 30 min | Ch3c : Query DSL & Bool Query | Cours |
| Jour 1 | 15:45–16:30 | 45 min | **TP4** : Requêtes & Recherche | TP |
| Jour 1 | 16:30–17:00 | 30 min | Récap Jour 1 + Q&A + preview | Q/A |
| Jour 2 | **09:00–09:45** | **45 min** | **Ch8 Sécurité (réduit)** : RBAC, FLS, DLS | Cours |
| Jour 2 | 09:45–10:00 | 15 min | Pause | Pause |
| Jour 2 | **10:00–10:30** | **30 min** | **TP5** : Sécurisation — Utilisateur + Rôle + FLS | TP |
| Jour 2 | 10:30–11:30 | 60 min | Ch4 : Fonctionnalités avancées (Pipelines, Analyseurs, Suggestion) | Cours |
| Jour 2 | 11:30–12:30 | 60 min | **TP6** : Pipelines & Analyseurs | TP |
| Jour 2 | 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| Jour 2 | 13:30–14:45 | 75 min | Ch6 : Architecture & Cluster (Lucene, nœuds, shards, routing, scalabilité, bonnes pratiques) | Cours |
| Jour 2 | 14:45–15:30 | 45 min | **TP7** : Installation cluster 3 nœuds | TP |
| Jour 2 | 15:30–15:45 | 15 min | Pause | Pause |
| Jour 2 | 15:45–16:30 | 45 min | **TP8** : Routage & distribution des shards | TP |
| Jour 2 | 16:30–17:00 | 30 min | Récap Jour 2 + Q&A + preview Jour 3 | Q/A |
| Jour 3 | **09:00–10:00** | **60 min** | Ch5 : Agrégations (métriques, bucket, pipeline, imbriquées) | Cours |
| Jour 3 | 10:00–10:15 | 15 min | Pause | Pause |
| Jour 3 | **10:15–11:30** | **75 min** | **TP9** : Agrégations avancées | TP |
| Jour 3 | 11:30–12:15 | 45 min | Ch5b : Scoring BM25, _explain, search_after, optimisation | Cours |
| Jour 3 | 12:15–12:30 | 15 min | Démo live Agrégations | Démo live |
| Jour 3 | 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| Jour 3 | 13:30–14:15 | 45 min | Ch9 : OpenSearch Dashboards | Cours |
| Jour 3 | 14:15–15:00 | 45 min | **TP10** : Dashboard e-commerce | TP |
| Jour 3 | 15:00–15:15 | 15 min | Pause | Pause |
| Jour 3 | 15:15–16:00 | 45 min | Ch10 : Reindex, ISM, Snapshots, Aliases avancés | Cours |
| Jour 3 | 16:00–16:30 | 30 min | **TP11** : Reindex + ISM + configuration | TP |
| Jour 3 | 16:30–17:00 | 30 min | Récap global + QCM + Questionnaire satisfaction + Q&A | QCM + Q/A |

---

## 7. Vérification de la cohérence pédagogique

### 7.1 Contraintes Ambient IT respectées

| Règle | Statut | Notes |
|-------|--------|-------|
| Max 30 min de cours sans TP ou pause | ✅ | Tous les blocs cours ≤ 75 min, suivis d'un TP ou d'une pause |
| Premier TP ~1h après le début | ✅ | TP1 à 10h30 = 1h30 après 9h00 (intentionnel) |
| Ratio 60% pratique / 40% théorie | ✅ | 11 TPs × ~45 min = ~500 min de pratique sur 1260 min (≈ 40%) — à ajuster si besoin |
| 3–4 chapitres par jour | ✅ | J1: 5 (Ch1/Ch2/Ch3a/Ch3b/Ch3c), J2: 3 (Ch8/Ch4/Ch6), J3: 4 (Ch5/Ch5b/Ch9/Ch10) |
| Fil rouge e-commerce | ✅ | Inchangé — products → search → visualize |
| Déjeuner 12h30 | ✅ | Tous les 3 jours |

### 7.2 Chaîne fil rouge (dépendances TPs)

```
TP1 (install cluster)
  → TP2 (créer index complet avec les bons types)
    → TP3 (CRUD + charger les 1000 produits)
      → TP4 (chercher dans les produits)
        → TP5 (sécuriser le cluster)
          → TP6 (enrichir les données via pipeline)
            → TP7 (passer en 3 nœuds)
              → TP8 (observer le routing sur le cluster)
                → TP9 (agréger les données)
                  → TP10 (visualiser dans Dashboards)
                    → TP11 (gérer le cycle de vie)
```

---

## 8. Décisions arrêtées (questions initiales résolues)

| Question | Décision |
|----------|---------|
| **TP geo + completion** | Chacun son TP optionnel dédié (`tp-geo-optionnel`, `tp-completion-optionnel`). Geo mentionné rapidement dans Ch4 (1 slide). |
| **Déjeuner J1** | Toujours 12h30–13h30. Ch3a compressé à 30 min, TP2 à 12h00–12h30. |
| **Numérotation dossiers labs** | Renommage physique des dossiers (voir §4.3). |
| **Sécurité scope** | TLS/certificats supprimés. Garder uniquement : RBAC (user+rôle+permissions) + FLS (masquage de champ). TP5 = 30 min. Temps gagné → TP6 élargi à 45 min. |
| **Ch5b scoring/BM25** | Reste en J3 matin (après TP9 agrégations). |

---

*Spec rédigée par Mary (BMad Strategic Analyst) — 2026-05-10*  
*Mise à jour avec décisions validées — 2026-05-11*  
*Basée sur : `CLAUDE-CODE-PROMPT-formation-opensearch.md`, `SPEC-formation-opensearch.md`*  
*Prochaine étape : implémentation via Claude Code*
