# OpenSearch 3.6 Training — Complete Project Specification

> **Document type**: Training production spec  
> **Status**: Ready for implementation  
> **Version**: 1.0 — 2026-05-05  
> **Audience**: Claude Code / developers generating all training materials  
> **Language note**: This spec is in English. All generated training content (slides, guides, labs, data) must be in **French** unless noted otherwise.

---

## 1. Project Overview

### 1.1 Mission Statement

Produce a complete, self-contained, GitHub-ready training kit for a **3-day (21-hour) OpenSearch 3.6 course** — covering everything from cluster setup to security — delivered in person or via screen share. The kit must be ready to clone and use with zero additional preparation.

### 1.2 Pedagogical Philosophy (Ambient IT Standards — Non-Negotiable)

| Rule | Constraint |
|------|-----------|
| Theory/Practice ratio | 40% theory / 60% practice |
| Max continuous lecture | 30 minutes without a lab |
| Slides per day | 30–50 slides on white/light background |
| Chapters per day | 3–4 chapters, each 5–10 bullet points |
| Thread | Single red thread: build an e-commerce search engine over 3 days |
| Intro demo | Live OpenSearch demo before any theory on Day 1 |
| First lab | Within ~1 hour of course start (Day 1 gauge) |
| Chapter opener | "Et si / Comment" (What if / How) framing — problem before solution |
| Bonus labs | Always include a bonus section for fast learners |
| Morning recap | 5–10 min oral Q&A on previous day's content |
| End of Day 3 | QCM quiz + satisfaction survey (last 30 min, Digiforma sends at 16:00) |
| Attendance | Remind participants to sign attendance sheet each half-day |

### 1.3 Target Audience

- French-speaking developers or ops engineers with little to no OpenSearch/Elasticsearch experience
- Comfortable with REST APIs, basic JSON, command-line usage
- May or may not know SQL (comparison used as teaching bridge)

### 1.4 Delivery Modes

- In-person classroom OR remote screen share
- Slides must be readable both projected and on screen

---

## 2. Deliverables Inventory

The repository root is `opensearch-formation/`. Every path below is relative to that root.

### 2.1 Full File Tree

```
opensearch-formation/
├── README.md
├── LICENSE
│
├── slides/
│   ├── jour-1/index.html
│   ├── jour-2/index.html
│   ├── jour-3/index.html
│   ├── assets/
│   │   ├── css/theme.css
│   │   ├── img/                  (diagrams, schemas)
│   │   └── js/
│   └── shared/components.html
│
├── guide-formateur/
│   ├── jour-1-guide.md
│   ├── jour-2-guide.md
│   ├── jour-3-guide.md
│   └── timings.md
│
├── infrastructure/
│   ├── docker-compose.yml
│   ├── docker-compose.cluster.yml
│   ├── opensearch/
│   │   ├── opensearch.yml
│   │   ├── jvm.options
│   │   └── certs/
│   └── dashboards/
│       └── opensearch_dashboards.yml
│
├── data/
│   ├── products.json
│   ├── products-bulk.ndjson
│   ├── stores.json
│   ├── logs-sample.json
│   └── generate-data.py
│
├── labs/
│   ├── tp1-installation/
│   │   ├── README.md
│   │   └── solution/
│   ├── tp2-crud-api/
│   │   ├── README.md
│   │   ├── exercices.sh
│   │   └── solution/solution.sh
│   ├── tp3-requetes-agregations/
│   │   ├── README.md
│   │   ├── exercices.sh
│   │   └── solution/
│   ├── tp4-fonctionnalites-avancees/
│   │   ├── README.md
│   │   ├── exercices.sh
│   │   └── solution/
│   ├── tp5-dashboards/
│   │   ├── README.md
│   │   ├── saved-objects-export.ndjson
│   │   └── solution/
│   ├── tp6-cluster/
│   │   ├── README.md
│   │   └── solution/
│   └── tp7-securite/
│       ├── README.md
│       └── solution/
│
├── scripts/
│   ├── setup.sh
│   ├── seed-data.sh
│   ├── reset.sh
│   └── check-health.sh
│
└── quiz/
    ├── quiz-jour-1.md
    ├── quiz-jour-2.md
    └── quiz-final.md
```

---

## 3. Slide Specifications (reveal.js)

### 3.1 Technical Stack

- **Framework**: reveal.js v5.x
- **Code highlighting**: Plugin `highlight.js` (built into reveal.js 5.x)
- **Speaker notes**: Use `Note:` syntax inside each `<section>` — visible with `S` key
- **Navigation**: Keyboard arrows, overview mode (`O`), full screen
- **PDF export**: Available via `?print-pdf` URL parameter
- **Responsive**: Must render correctly at 1920×1080, 1280×720, and in browser window

### 3.2 Visual Theme

| Element | Specification |
|---------|--------------|
| Background | `#ffffff` (white) or `#f8fafc` (very light grey) — NO dark backgrounds |
| Title text | `#0f172a` (slate-900) |
| Body text | `#475569` (slate-600) |
| Primary accent | `#2563eb` (blue) |
| Success/positive | `#16a34a` (green) |
| Advanced/premium | `#9333ea` (violet) |
| Warning/caution | `#ea580c` (orange) |
| Code blocks | Background `#0f172a`, text `#86efac` (light green), monospace font |
| Chapter transition slides | Solid accent color background + white text |
| Font | `Inter`, fallback `system-ui`, code: `'JetBrains Mono', 'Fira Code', monospace` |

### 3.3 Required Slide Types (per chapter)

Every chapter must contain all six types:

1. **"Et si / Comment" opener** — poses a real problem the chapter will solve (1 slide)
2. **Content slides** — theory with code examples, schemas, comparison tables (3–8 slides)
3. **Live demo slide** — explicit instructions to the trainer: what to type, in what order, what to highlight (1 slide)
4. **Lab slide** — numbered objectives + bonus section (1 slide)
5. **Quick quiz slide** — 3–4 multiple-choice questions to check understanding (1 slide)
6. **Chapter recap** — visual summary of key concepts (1 slide)

### 3.4 Speaker Notes Requirement

Every slide must have speaker notes containing:
- Exact verbal script (informal French, tutoiement with participants)
- Key points not to miss
- Transition to next slide
- Common learner questions + answers
- Recommended timing

### 3.5 Day-by-Day Slide Count Targets

| Day | Min | Max | Chapters |
|-----|-----|-----|----------|
| Jour 1 | 30 | 50 | 3 (Intro, Install, Fonctionnement/DSL) |
| Jour 2 | 30 | 50 | 2 (Avancé, Dashboards) |
| Jour 3 | 30 | 50 | 3 (Cluster, Admin, Sécurité) |

---

## 4. Trainer Guide Specifications

### 4.1 File Format

One Markdown file per day: `guide-formateur/jour-X-guide.md`

### 4.2 Required Structure per File

```markdown
# Jour X — Guide formateur

## Timing global
| Heure | Durée | Activité | Type |
|-------|-------|----------|------|

## Slide N : [Title]
**Timing** : X min
**Ce que tu dis** :
> "..."
**Points clés** :
- ...
**Questions fréquentes** :
- Q: ... → R: ...
**Transition** :
> "..."
---
```

### 4.3 Content Requirements per Slide Block

- Verbal script in informal French (tutoiement)
- Indicative timing
- Anecdotes and real-world experience to share
- Common learner pitfalls
- Typical learner questions + answers
- Alert signals: "if participants do X, they haven't understood Y"
- Live demo tips: exact commands, sequence, what to show

### 4.4 timings.md

A consolidated minute-by-minute schedule for all 3 days:

```markdown
| Jour | Heure | Durée | Activité | Type |
|------|-------|-------|----------|------|
```

Types: `Cours`, `TP`, `Démo live`, `Pause`, `Déjeuner`, `Q/A`, `QCM`

---

## 5. Course Programme — Detailed

### 5.1 Day 1 — Fondamentaux & Prise en main (9:00–17:00)

#### 9:00–9:30 — Opening
- Trainer introduction + course overview
- Tour de table (~1 min/person): experience, level, expectations
- Explicit scope exclusions

#### 9:30–9:45 — Live Demo (Ice Breaker) — BEFORE any theory
- Open terminal, show running cluster
- Execute: `GET /demo-products/_search` (match + filter)
- Show JSON response, a single document
- SQL comparison: "En SQL: LIKE + JOIN + ORDER BY. Ici: une requête, 5ms."
- Goal: demystify, show the end result of 3 days
- **Trainer prep**: docker-compose + seed-data.sh done in advance; fallback screenshots ready

#### 9:45–10:30 — Chapter 1: Introduction à OpenSearch
Topics:
- OpenSearch use cases: e-commerce, logs, SIEM, analytics
- History: Elasticsearch → AWS fork → OpenSearch (why?)
- Version roadmap: 1.x → 2.x → 3.x, Lucene 10 changes
- Architecture: cluster, nodes, index, shards, documents
- Ecosystem: Dashboards, Data Prepper, clients, plugins
- OpenSearch vs Elasticsearch: comparison table

#### 10:30 — Coffee break

#### 10:45–11:30 — Chapter 2: Installation & Configuration
Topics:
- Prerequisites: hardware, OS, Docker, `vm.max_map_count`
- Install via Docker Compose (live demo)
- OpenSearch Dashboards installation
- Config files: `opensearch.yml`, `jvm.options`
- Verification: curl, `_cluster/health`, Dashboards UI
- Admin principles: REST API, Cat APIs

#### 11:30–12:15 — Lab TP1: Installation en local (45 min)
1. Start provided docker-compose
2. Verify cluster health (green)
3. Explore Cat APIs (`_cat/nodes`, `_cat/indices`)
4. Navigate Dashboards UI
5. Modify `cluster.name`, restart, verify
- **Bonus**: install without Docker (tar.gz)

#### 12:15–13:30 — Lunch

#### 13:30–14:15 — Chapter 3a: Fonctionnement d'OpenSearch
Topics:
- Internal architecture: inverted index, Lucene segments, refresh
- JSON documents vs SQL rows (flexible schema, denormalization)
- REST API: full CRUD (PUT, GET, POST, DELETE)
- Bulk API for mass indexing
- Index creation and management (settings, shard count)
- Mappings: field types (text, keyword, float, boolean, date, geo_point)
- Stored fields (`_source`) vs indexed (inverted index)
- Dynamic vs explicit mapping

#### 14:15–15:00 — Lab TP2: CRUD & API (45 min)
1. Create `products` index with explicit mapping
2. Manually index 20 products (PUT _doc)
3. Read, update, delete documents
4. Use Bulk API to load `products-bulk.ndjson` (1000+ products)
5. Verify with `_cat/indices` and `_search match_all`
- **Bonus**: Python/bash script to generate 5000 random products

#### 15:00 — Break

#### 15:15–15:45 — Chapter 3b: Query DSL & Aggregations
Topics:
- Query DSL: match, term, range, wildcard, multi_match
- Bool query: must, filter, should, must_not (score impact difference)
- Scoring: BM25 (TF, IDF, field length), `_explain` API
- Aggregations: metric (avg, sum, stats), bucket (terms, histogram, date_histogram), pipeline
- Pagination: from/size, search_after

#### 15:45–16:30 — Lab TP3: Requêtes & Agrégations (45 min)
1. Full-text search in product names
2. Filter: in-stock, price between X and Y, specific category
3. Bool query combining match + filter + must_not
4. Aggregation: average price by category
5. Aggregation: price histogram (100€ ranges)
6. `_explain` on a result
- **Bonus**: nested aggregation (top 5 categories → most/least expensive product)

#### 16:30–17:00 — Day 1 Recap & Q&A
- Key concepts summary
- Preview of Day 2

---

### 5.2 Day 2 — Fonctionnalités avancées & Dashboards (9:00–17:00)

#### 9:00–9:15 — Day 1 Recap
- 6 quick oral questions on yesterday's content
- "Who needs help finishing yesterday's labs?"

#### 9:15–10:30 — Chapter 4: Fonctionnalités avancées

**9:15–9:45 — Ingest Pipelines**
- Pipeline concept (chained processors)
- Common processors: set, remove, rename, lowercase, trim, grok, dissect, date
- Simulate API to test pipelines
- Default pipeline on an index

**9:45–10:15 — Analyseurs & Tokenizers**
- Analysis chain: Char Filters → Tokenizer → Token Filters → Tokens
- Char filters: html_strip, pattern_replace, mapping
- Tokenizers: standard, whitespace, keyword, ngram, edge_ngram
- Token filters: lowercase, stemmer, synonym, stop, asciifolding
- Create a custom French analyzer (stemmer + asciifolding)
- `_analyze` API to test

#### 10:15 — Break

**10:30–11:00 — Tri, Suggestion & Surlignage**
- Result sorting: simple, multi-criteria, by script
- Completion suggester: `completion` type, autocomplete, fuzzy
- Highlighting: pre_tags/post_tags, fragment_size
- Term suggester: "Did you mean?"

**11:00–11:30 — Géo & Optimisation**
- Geographic relevance: geo_point, geo_distance, geo_bounding_box, geo_shape
- Sort by geographic distance
- Indexing optimization: Bulk API, refresh_interval, replicas=0 during load, dynamic:strict, routing
- Query optimization: filter vs must, `_source` filtering, search_after, avoid leading wildcards

#### 11:30–12:30 — Lab TP4: Fonctionnalités avancées (60 min)
1. Create ingest pipeline (lowercase category, add timestamp, trim)
2. Create custom French analyzer (stemmer + asciifolding)
3. Reindex products with new analyzer (test with `_analyze`)
4. Add completion field, implement autocomplete
5. Enable highlighting on results
6. Index stores (geo_point), test geo_distance
- **Bonus**: "Did you mean?" with term suggester + fuzzy

#### 12:30–13:30 — Lunch

#### 13:30–15:00 — Chapter 5: Visualisation avec OpenSearch Dashboards

**13:30–14:00 — Principles**
- Dashboards interface: Discover, Visualize, Dashboard, Management
- Index Patterns: creation, wildcards, date field
- Discover: raw data exploration, KQL, time filters
- Saved Objects: JSON export/import, naming, versioning

**14:00–14:30 — Aggregations & Visualizations**
- Aggregation types in Dashboards: Bucket (terms, date_histogram, range, filters), Metric (count, avg, sum, unique count, percentiles), Pipeline (moving avg, derivative)
- Visualization types: Bar, Line, Pie, Area, Metric, Data Table, Heat Map, Maps
- Choosing the right visualization for a business question
- Configuring axes, legends, colors, labels

**14:30–15:00 — Maps & Dashboards**
- Coordinate Map (geo_point, geohash)
- Region Map (by country/region)
- Building a dashboard: assemble visualizations, layout, filters, time range
- Share and embed

#### 15:00 — Break

#### 15:15–16:30 — Lab TP5: Dashboard e-commerce (75 min)
1. Create Index Pattern for `products`
2. Explore with Discover (filters, KQL: `category: "Electronics" AND price > 500`)
3. Create visualizations:
   - Metric: total product count, average price
   - Pie Chart: category breakdown
   - Bar Chart: top 10 categories by product count
   - Line Chart: average price by price range (histogram)
   - Data Table: top 20 most expensive products
   - Coordinate Map: store locations
4. Assemble the complete dashboard
- **Bonus**: export dashboard as JSON; import `saved-objects-export.ndjson`

#### 16:30–17:00 — Day 2 Recap & Q&A

---

### 5.3 Day 3 — Cluster, Administration & Sécurité (9:00–17:00)

#### 9:00–9:15 — Day 2 Recap
- 6 quick questions
- Help with unfinished labs

#### 9:15–10:15 — Chapter 6: Configuration du Cluster
Topics:
- Node types: Master, Data, Ingest, Coordinating (roles, dedicated vs multi-role)
- Discovery: seed_hosts, initial_master_nodes, quorum (min 3 master-eligible)
- Shards: primary (immutable count), replica (dynamic), sizing (10–50 GB)
- Routing: hash(_id) % shard_count, custom routing
- Index settings: static vs dynamic, `_close`/`_open`
- Aliases: creation, zero-downtime switchover, filtered aliases
- Index Templates: index_patterns, settings, mappings, automatic aliases

#### 10:15 — Break

#### 10:30–11:30 — Chapter 7: Administration du Cluster
Topics:
- Snapshots: snapshot repositories (fs, S3), create/restore
- ISM (Index State Management): policies, states (hot → warm → cold → delete), rollover, force_merge
- Monitoring: `_cluster/health`, `_nodes/stats`, `_cat` APIs, key metrics (heap, CPU, disk, latency)
- Bottleneck diagnosis: common causes, remediation
- `_cluster/allocation/explain`: why a shard is unassigned

#### 11:30–12:30 — Lab TP6: Cluster multi-nodes (60 min)
1. Switch to `docker-compose.cluster.yml` (3 nodes)
2. Verify shard distribution (`_cat/shards`, `_cat/allocation`)
3. Create index template for `products-*`
4. Set up aliases (v1 → v2 switchover)
5. Create a snapshot
6. Configure ISM policy (hot → delete after 30d)
7. Monitor with `_nodes/stats`, `_cat/nodes`
- **Bonus**: simulate node failure (`docker stop`), observe recovery

#### 12:30–13:30 — Lunch

#### 13:30–14:30 — Chapter 8: Sécurité dans OpenSearch
Topics:
- Security Plugin (native): overview
- TLS/SSL: transport layer (inter-node), REST layer (client)
- Authentication: internal users, LDAP, SAML, OpenID Connect
- Authorization: RBAC (roles, permissions), cluster vs index permissions
- Document Level Security (DLS): filter docs by role
- Field Level Security (FLS): hide fields by role
- Audit logging: configuration, event categories, compliance

#### 14:30–15:15 — Lab TP7: Sécurisation du cluster (45 min)
1. Enable security plugin (remove `DISABLE_SECURITY_PLUGIN`)
2. Configure TLS with demo certificates
3. Connect as `admin`
4. Create role `products_reader` (read-only on `products-*`)
5. Create user `analyst`, map to role
6. Test: analyst can read but NOT write
7. Enable audit logging, verify logs
- **Bonus**: DLS → analyst sees only `electronics` category

#### 15:15 — Break

#### 15:30–16:00 — Global 3-Day Recap
- Visual summary of everything built (complete red thread)
- Resources to go further (official docs, forum, blog, GitHub)
- Production deployment advice

#### 16:00–16:30 — QCM & Satisfaction Survey
- Validation quiz (Digiforma link sent at 16:00)
- Satisfaction questionnaire
- Final Q&A with trainer

---

## 6. Infrastructure Specifications

### 6.1 docker-compose.yml (Single node — Days 1 & 2)

| Parameter | Value |
|-----------|-------|
| OpenSearch image | `opensearchproject/opensearch:3.6.0` |
| Dashboards image | `opensearchproject/opensearch-dashboards:3.6.0` |
| Discovery mode | `single-node` |
| Security plugin | **DISABLED** (for training simplicity) |
| API port | `9200` |
| Performance Analyzer | `9600` |
| Dashboards port | `5601` |
| Data volume | Persistent named volume |
| Network | Dedicated bridge network |
| Admin password | `OPENSEARCH_INITIAL_ADMIN_PASSWORD` env var (required since OS 2.12+) |
| Health check | Curl `_cluster/health` until `green` |

### 6.2 docker-compose.cluster.yml (3 nodes — Day 3)

| Parameter | Value |
|-----------|-------|
| Nodes | `opensearch-node1`, `opensearch-node2`, `opensearch-node3` |
| Dashboards | 1 instance connected to all 3 nodes |
| Node roles | All nodes: master-eligible + data |
| Security plugin | **ENABLED** with demo certificates |
| Discovery | `seed_hosts`, `initial_master_nodes` set to all 3 |
| Volumes | One named volume per node |
| Network | Dedicated bridge network |
| Quorum | 3 master-eligible nodes (minimum for fault tolerance) |

### 6.3 opensearch.yml (custom)

Must configure:
- `cluster.name`
- `node.name`
- `network.host: 0.0.0.0`
- `discovery.seed_hosts` / `cluster.initial_master_nodes` (cluster setup)
- `plugins.security.disabled: true` (single-node) or security config (cluster)

### 6.4 jvm.options

- Heap: `-Xms512m -Xmx512m` (training environment — low memory)
- GC: G1GC recommended

### 6.5 opensearch_dashboards.yml

- `opensearch.hosts`: point to OpenSearch container
- `server.host: 0.0.0.0`
- Security settings matching the docker-compose mode

---

## 7. Scripts Specifications

### 7.1 setup.sh

```
Checks prerequisites:
  - Docker installed and running
  - docker-compose / docker compose available
  - Available memory >= 4GB (warn if less)
  - vm.max_map_count >= 262144 (set automatically on Linux, warn on Mac)
Runs:
  - docker-compose up -d
  - Polls _cluster/health until green (timeout 120s)
  - Runs seed-data.sh
  - Prints success message with access URLs
```

### 7.2 seed-data.sh

```
Waits for OpenSearch to be ready (curl retry loop)
Creates index with explicit mapping:
  - products (text, keyword, float, boolean, date, integer, nested tags)
  - stores (text, keyword, geo_point, integer)
  - logs (text, keyword, date, integer, long)
Loads via Bulk API:
  - products-bulk.ndjson (1000+ documents)
  - stores.json (50+ stores)
  - logs-sample.json (500+ log lines)
Verifies document counts
Prints summary table
```

### 7.3 reset.sh

```
Deletes all training indices: products, products-*, stores, logs-*
Re-runs seed-data.sh
Prints confirmation
(Used when a participant has broken their environment)
```

### 7.4 check-health.sh

```
Outputs:
  - Cluster health (color, number of nodes, active shards)
  - Node list with roles and status
  - Index list with document counts and sizes
  - Recent errors from logs (last 20 lines)
```

---

## 8. Data Specifications

### 8.1 products.json / products-bulk.ndjson

**Volume**: 1000+ documents

**Schema**:

```json
{
  "name": "string (French product name)",
  "description": "string (French, 2-4 sentences)",
  "category": "string (enum, see below)",
  "sub_category": "string",
  "brand": "string",
  "price": "float (EUR)",
  "original_price": "float (EUR, >= price)",
  "currency": "EUR",
  "in_stock": "boolean",
  "stock_quantity": "integer (0 if out of stock)",
  "rating": "float (1.0–5.0)",
  "reviews_count": "integer",
  "tags": ["array", "of", "strings"],
  "created_at": "ISO 8601 datetime (last 12 months)",
  "updated_at": "ISO 8601 datetime",
  "seller": "string",
  "weight_kg": "float",
  "color": "string (French color name)"
}
```

**Category distribution**:

| Category | % | Sub-categories |
|----------|---|---------------|
| Electronics | 30% | Laptops, Smartphones, Tablettes, Casques, Appareils photo |
| Vêtements | 20% | Chemises, Pantalons, Chaussures, Vestes |
| Maison & Jardin | 15% | Meubles, Cuisine, Décoration |
| Sports | 10% | Course, Cyclisme, Natation |
| Livres | 10% | Fiction, Non-Fiction, Informatique, BD |
| Alimentation | 10% | Bio, Snacks, Boissons |
| Jouets | 5% | Éducatif, Jeux de société, Plein air |

**Data quality requirements**:
- All names and descriptions in French
- Realistic EUR prices per category
- ~20% out-of-stock products (`in_stock: false`, `stock_quantity: 0`)
- Dates spread across last 12 months
- Varied ratings and review counts for interesting aggregations
- `products-bulk.ndjson` uses OpenSearch Bulk API format (action + source lines)

### 8.2 stores.json

**Volume**: 50+ stores

**Schema**:

```json
{
  "name": "string",
  "city": "string",
  "address": "string (French postal address)",
  "location": { "lat": float, "lon": float },
  "type": "flagship | standard | outlet | click-and-collect",
  "opening_hours": "HH:MM-HH:MM",
  "categories": ["array", "of", "category strings"],
  "employee_count": integer
}
```

**Geographic coverage**: Paris, Lyon, Marseille, Toulouse, Bordeaux, Lille, Strasbourg, Nantes, Nice, Rennes, Montpellier, Grenoble — realistic GPS coordinates.

### 8.3 logs-sample.json

**Volume**: 500+ lines

**Schema**:

```json
{
  "timestamp": "ISO 8601",
  "level": "DEBUG | INFO | WARN | ERROR | FATAL",
  "service": "string (e.g. payment-service, product-api)",
  "message": "string",
  "http_status": "integer (optional)",
  "response_time_ms": "integer (optional)",
  "user_id": "string (optional)",
  "trace_id": "string"
}
```

**Distribution**: ~70% INFO, ~15% WARN, ~10% ERROR, ~5% DEBUG/FATAL — varied services, realistic messages.

### 8.4 generate-data.py

Python script that:
- Accepts `--count` argument (default 1000)
- Generates products with realistic French data using faker or hardcoded lists
- Outputs both `products.json` and `products-bulk.ndjson`
- Optionally generates stores and logs
- No external dependencies beyond stdlib (or `faker` if available)

---

## 9. Lab Specifications (TPs)

### 9.1 Standard Lab Template

```markdown
# TP X — [Title]

## Objectif
[One sentence: what we accomplish]

## Prérequis
- [What must be done first]

## Durée estimée
XX minutes

## Contexte (fil rouge)
[Where we are in the e-commerce search engine project]

## Exercices

### Exercice 1 : [Title]
**Objectif** : ...
**Instructions** :
1. ...
2. ...
**Indice** : ...
**Vérification** : Vous devriez obtenir...

## TP Bonus (pour les plus rapides)
...

## Vérification finale
- [ ] Checklist item
```

### 9.2 exercices.sh Template

Each `.sh` file contains:
- Curl commands with `# TODO: complete this query` placeholders
- Explanatory comments in French
- Section separators
- Variable definitions for `BASE_URL`, `INDEX`

### 9.3 solution.sh Template

- Complete curl commands with correct answers
- Comments explaining why each solution works
- Expected output examples

### 9.4 Lab Summary

| Lab | Day | Duration | Key Skills | Red Thread |
|-----|-----|----------|-----------|------------|
| TP1 — Installation | 1 | 45 min | Docker, Cat APIs, Dashboards UI | Environment setup |
| TP2 — CRUD & API | 1 | 45 min | Mapping, Bulk API, CRUD | Load product catalog |
| TP3 — Requêtes & Agrégations | 1 | 45 min | Query DSL, bool, aggregations | Search & analyze products |
| TP4 — Fonctionnalités avancées | 2 | 60 min | Pipelines, analyzers, geo, completion | Enrich & optimize search |
| TP5 — Dashboard | 2 | 75 min | Dashboards, KQL, visualizations | Business intelligence |
| TP6 — Cluster | 3 | 60 min | Multi-node, shards, aliases, ISM, snapshots | Production setup |
| TP7 — Sécurité | 3 | 45 min | Security plugin, TLS, RBAC, DLS | Secure the cluster |

---

## 10. Quiz Specifications

### 10.1 Format

Markdown with:
- Numbered questions
- A–D multiple-choice options
- Answers in collapsed `<details>` block
- Brief explanation after each answer

### 10.2 quiz-jour-1.md (10 questions)

Topics: architecture (cluster/node/shard/document), documents vs SQL, CRUD API, mappings, field types, Query DSL, bool query, BM25 scoring, metric aggregations, bucket aggregations.

### 10.3 quiz-jour-2.md (10 questions)

Topics: ingest pipelines, analysis chain, custom analyzers, tokenizers, completion suggester, highlighting, geo_point queries, indexing optimization, Dashboards index patterns, visualization types.

### 10.4 quiz-final.md (20 questions)

Topics: all of the above + cluster configuration (node roles, discovery, quorum), shard sizing and routing, aliases and zero-downtime reindexing, index templates, ISM policies, snapshot/restore, Security Plugin, TLS layers, RBAC, DLS/FLS, audit logging, performance monitoring.

---

## 11. README.md Specification

The root README must contain:

1. **Quick Start** (< 5 minutes to running cluster)
2. **Prerequisites** table (Docker version, RAM, disk, OS)
3. **Repository structure** overview
4. **Day-by-day usage guide** (what to run each morning)
5. **Troubleshooting** (common issues: port conflicts, memory, `vm.max_map_count`)
6. **Data reset** instructions
7. **Links** to official OpenSearch docs

---

## 12. Technical Constraints & Warnings

### 12.1 OpenSearch 3.x Compatibility

- Always use **3.6 APIs**, not 2.x or Elasticsearch equivalents
- The `_type` field was removed — do not use it
- Security plugin is included natively (no separate install)
- `OPENSEARCH_INITIAL_ADMIN_PASSWORD` is mandatory since OS 2.12+ — always set it
- Lucene 10 (bundled in OS 3.x) changes some internal behaviors — mention where relevant

### 12.2 Docker Images

- Use exact tags: `opensearchproject/opensearch:3.6.0` and `opensearchproject/opensearch-dashboards:3.6.0`
- If these tags are unavailable, fall back to `opensearchproject/opensearch:latest` with a comment

### 12.3 Security Modes

| Mode | Days | `DISABLE_SECURITY_PLUGIN` | TLS |
|------|------|--------------------------|-----|
| Single-node (no security) | 1–2 | `true` | Off |
| Cluster (security on) | 3 | Not set | Demo certs |

### 12.4 Red Thread Continuity

Labs must chain: each lab builds on the state left by the previous one.

| Lab produces | Lab consumes |
|-------------|-------------|
| TP1: running cluster | TP2 |
| TP2: `products` index with 1000+ docs | TP3, TP4 |
| TP4: French analyzer, geo data | TP5 |
| TP5: dashboards | (standalone) |
| TP6: cluster config, aliases, templates | TP7 |
| TP7: security layer | (final state) |

### 12.5 French Language Requirement

All of the following must be in French:
- All product names and descriptions
- All store names and addresses
- All lab README.md files
- All trainer guide scripts
- All slide content (titles, bullet points, code comments)
- All quiz questions and answers

Exception: code, API calls, JSON keys, and CLI commands remain in English (as they are in the real tool).

---

## 13. Acceptance Criteria

The kit is complete and correct when:

- [ ] All files in the repository tree (Section 2.1) exist
- [ ] `docker-compose.yml` starts cleanly and cluster reaches green health
- [ ] `docker-compose.cluster.yml` starts 3 nodes and shows green cluster health
- [ ] `seed-data.sh` loads at least 1000 products, 50 stores, 500 log lines
- [ ] `reset.sh` restores the environment to a clean state
- [ ] Each `exercices.sh` file is runnable and has meaningful TODOs
- [ ] Each `solution.sh` file passes all exercises with correct output
- [ ] All 3 slide files (`jour-1/index.html`, etc.) open in browser and display correctly
- [ ] Speaker notes are present on every slide (visible with `S` key)
- [ ] No dark backgrounds in slides (white/light only)
- [ ] Chapter transition slides use accent colors
- [ ] Trainer guides cover every slide with timing + verbal script
- [ ] `timings.md` accounts for all 21 hours across 3 days
- [ ] All quizzes have correct answers in `<details>` blocks
- [ ] README.md leads a first-timer from zero to running cluster in < 5 steps
- [ ] All training content is in French; code/APIs remain in English

---

## 14. Generation Order (Recommended for Claude Code)

To avoid dependency issues, generate in this order:

1. **data/** — `products.json`, `products-bulk.ndjson`, `stores.json`, `logs-sample.json`, `generate-data.py`
2. **infrastructure/** — `docker-compose.yml`, `docker-compose.cluster.yml`, config files
3. **scripts/** — `setup.sh`, `seed-data.sh`, `reset.sh`, `check-health.sh`
4. **labs/** — TP1 through TP7 (README + exercices.sh + solution.sh)
5. **quiz/** — `quiz-jour-1.md`, `quiz-jour-2.md`, `quiz-final.md`
6. **guide-formateur/** — `jour-1-guide.md`, `jour-2-guide.md`, `jour-3-guide.md`, `timings.md`
7. **slides/** — `jour-1/index.html`, `jour-2/index.html`, `jour-3/index.html` + assets
8. **README.md** — root quick-start guide

---

*Spec generated by Mary (BMad Strategic Analyst) — 2026-05-05*  
*Based on: `CLAUDE-CODE-PROMPT-formation-opensearch.md`*
