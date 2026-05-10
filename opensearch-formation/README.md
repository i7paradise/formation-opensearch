# Formation OpenSearch 3.6

Kit de formation complet pour un cours de 3 jours (21 heures) sur OpenSearch 3.6, couvrant l'installation, la configuration, la recherche avancée, les dashboards, la gestion de cluster et la sécurité.

---

## Démarrage rapide (< 5 minutes)

```bash
# 1. Cloner le dépôt
git clone <url-du-repo> opensearch-formation
cd opensearch-formation

# 2. Lancer l'environnement (single-node, jours 1 & 2)
cd infrastructure
docker compose up -d

# 3. Vérifier que le cluster est healthy
curl http://localhost:9200/_cluster/health?pretty

# 4. Charger les données de démonstration
cd ..
bash scripts/seed-data.sh

# 5. Ouvrir Dashboards
open http://localhost:5601
```

---

## Prérequis

| Élément | Minimum | Recommandé |
|---------|---------|-----------|
| Docker | 24.x | 25.x ou plus |
| Docker Compose | 2.x | 2.24+ |
| RAM disponible | 4 GB | 8 GB |
| Espace disque | 10 GB | 20 GB |
| OS | Linux, macOS, Windows (WSL2) | Linux ou macOS |

> **macOS / Linux** : Aucune configuration supplémentaire nécessaire pour `vm.max_map_count` — le script `setup.sh` le gère automatiquement.

---

## Structure du dépôt

```
opensearch-formation/
├── README.md                        # Ce fichier
├── LICENSE
├── slides/                          # Présentations reveal.js
│   ├── jour-1/index.html            # Fondamentaux & Prise en main
│   ├── jour-2/index.html            # Fonctionnalités avancées & Dashboards
│   ├── jour-3/index.html            # Cluster, Administration & Sécurité
│   └── assets/css/theme.css         # Thème visuel partagé
├── guide-formateur/                 # Scripts verbaux et timing pour le formateur
│   ├── jour-1-guide.md
│   ├── jour-2-guide.md
│   ├── jour-3-guide.md
│   └── timings.md                   # Planning minute par minute
├── infrastructure/                  # Configuration Docker
│   ├── docker-compose.yml           # Single-node (jours 1 & 2)
│   ├── docker-compose.cluster.yml   # Cluster 3 nœuds (jour 3)
│   ├── opensearch/
│   │   ├── opensearch.yml
│   │   └── jvm.options
│   └── dashboards/
│       └── opensearch_dashboards.yml
├── data/                            # Données de démonstration
│   ├── products.json                # 1000+ produits (format JSON array)
│   ├── products-bulk.ndjson         # Format Bulk API pour OpenSearch
│   ├── stores.json                  # 50+ magasins avec coordonnées GPS
│   ├── logs-sample.json             # 500+ lignes de logs applicatifs
│   └── generate-data.py             # Générateur de données (--count N)
├── labs/                            # Travaux pratiques
│   ├── tp1-installation/            # Démarrage et Cat APIs (45 min)
│   ├── tp2-crud-api/                # Mapping, Bulk API, CRUD (45 min)
│   ├── tp3-requetes-agregations/    # Query DSL, Agrégations (45 min)
│   ├── tp4-fonctionnalites-avancees/ # Pipelines, Analyseurs, Géo (60 min)
│   ├── tp5-dashboards/              # Dashboard e-commerce (75 min)
│   ├── tp6-cluster/                 # Cluster multi-nœuds (60 min)
│   └── tp7-securite/                # Sécurité RBAC, TLS (45 min)
├── scripts/                         # Scripts utilitaires
│   ├── setup.sh                     # Installation complète en une commande
│   ├── seed-data.sh                 # Chargement des données initiales
│   ├── reset.sh                     # Réinitialisation de l'environnement
│   └── check-health.sh              # Vérification de l'état du cluster
└── quiz/                            # Quiz et évaluation
    ├── quiz-jour-1.md               # 10 questions (Fondamentaux)
    ├── quiz-jour-2.md               # 10 questions (Avancé & Dashboards)
    └── quiz-final.md                # 20 questions (Évaluation finale)
```

---

## Utilisation jour par jour

### Matin du Jour 1 (avant 9h00)
```bash
cd infrastructure
docker compose up -d
# Attendre que le cluster soit vert (~60 secondes)
curl http://localhost:9200/_cluster/health?pretty
cd ..
bash scripts/seed-data.sh
```

Ouvrir les slides : `slides/jour-1/index.html` dans un navigateur.

### Matin du Jour 2
```bash
# L'environnement du jour 1 doit être encore running
docker ps
# Si arrêté :
cd infrastructure && docker compose up -d
```

Ouvrir les slides : `slides/jour-2/index.html`

### Matin du Jour 3 — Basculer en mode cluster
```bash
# Arrêter le single-node
cd infrastructure
docker compose down

# Démarrer le cluster 3 nœuds (avec sécurité activée)
docker compose -f docker-compose.cluster.yml up -d

# Vérifier les 3 nœuds
curl -k -u admin:Admin@1234! https://localhost:9200/_cat/nodes?v
```

Ouvrir les slides : `slides/jour-3/index.html`

---

## Régénérer les données

```bash
# Réinitialiser à l'état initial
bash scripts/reset.sh

# Générer plus de produits (ex: 5000)
cd data
python3 generate-data.py --count 5000
cd ..
bash scripts/seed-data.sh
```

---

## Résolution de problèmes

### Le cluster ne démarre pas

**Problème** : `ERROR: [1] bootstrap checks failed`
```bash
# Sur Linux : augmenter vm.max_map_count
sudo sysctl -w vm.max_map_count=262144
# Rendre permanent :
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

**Problème** : Port 9200 ou 5601 déjà utilisé
```bash
# Vérifier ce qui utilise le port
lsof -i :9200
lsof -i :5601
# Arrêter le processus ou changer les ports dans docker-compose.yml
```

### Cluster en rouge ou jaune

```bash
bash scripts/check-health.sh
# Détail des shards non assignés :
curl http://localhost:9200/_cluster/allocation/explain?pretty
```

### Manque de mémoire

```bash
# Vérifier la mémoire dispo
docker stats --no-stream
# Réduire la heap JVM dans infrastructure/opensearch/jvm.options :
# -Xms256m -Xmx256m
# puis redémarrer
docker compose restart opensearch
```

### Données manquantes après redémarrage

```bash
bash scripts/seed-data.sh
```

### Réinitialiser complètement l'environnement

```bash
bash scripts/reset.sh
# Ou supprimer les volumes Docker :
docker compose down -v
docker compose up -d
bash scripts/seed-data.sh
```

---

## Ressources officielles

- **Documentation** : https://opensearch.org/docs/latest/
- **Forum** : https://forum.opensearch.org/
- **GitHub** : https://github.com/opensearch-project/OpenSearch
- **Blog** : https://opensearch.org/blog/
- **Changelog 3.x** : https://github.com/opensearch-project/OpenSearch/blob/main/CHANGELOG.md

---

## Licence

MIT — voir [LICENSE](LICENSE)
