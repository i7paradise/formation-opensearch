# TP1 — Installation & Démarrage

## Objectif

Démarrer un cluster OpenSearch local, explorer les APIs de base et se familiariser avec l'interface OpenSearch Dashboards.

## Prérequis

- Docker (version 20.10+) et Docker Compose (version 2.0+) installés
- Accès à un terminal (bash ou zsh)
- Ports 9200 et 5601 disponibles sur votre machine

## Durée estimée

45 minutes

## Contexte fil rouge

Bienvenue dans ce cours de formation OpenSearch ! Au fil de ces trois jours, vous allez construire progressivement un **moteur de recherche e-commerce** complet. Ce premier TP pose les fondations : démarrer l'environnement de travail, vérifier que tout fonctionne, et explorer les outils à votre disposition.

À l'issue de cette formation, votre moteur de recherche saura :
- Indexer un catalogue de milliers de produits
- Effectuer des recherches full-text intelligentes avec scoring de pertinence
- Proposer de l'autocomplétion et de la correction orthographique
- Analyser les données produits par agrégations
- Chercher des magasins par proximité géographique

---

## Architecture de l'environnement

```
┌─────────────────────────────────────────┐
│           Docker Compose                │
│                                         │
│  ┌─────────────────┐  ┌──────────────┐  │
│  │   OpenSearch    │  │  Dashboards  │  │
│  │  :9200 / :9600  │  │    :5601     │  │
│  └─────────────────┘  └──────────────┘  │
└─────────────────────────────────────────┘
```

- **OpenSearch 3.6** : moteur de recherche et d'analyse (API REST sur le port 9200)
- **OpenSearch Dashboards 3.6** : interface graphique web (port 5601)

---

## Exercice 1 — Démarrer le cluster

### 1.1 Cloner et préparer l'environnement

Assurez-vous d'être dans le répertoire racine du projet :

```bash
cd /chemin/vers/formation-opensearch
```

### 1.2 Lancer les conteneurs

```bash
cd infrastructure/
docker compose up -d
```

Attendez que les deux services soient démarrés (environ 30 à 60 secondes selon votre machine). Vérifiez l'état des conteneurs :

```bash
docker compose ps
```

Vous devriez voir `opensearch` et `opensearch-dashboards` avec l'état `healthy`.

### 1.3 Consulter les logs

Si quelque chose ne démarre pas :

```bash
docker compose logs opensearch
docker compose logs opensearch-dashboards
```

> **Note** : Si vous obtenez l'erreur `max virtual memory areas vm.max_map_count [65530] is too low`, exécutez sur Linux :
> ```bash
> sudo sysctl -w vm.max_map_count=262144
> ```

---

## Exercice 2 — Vérifier la santé du cluster

### 2.1 Premier appel API

Ouvrez un nouveau terminal et interrogez l'API de santé du cluster :

```
GET /_cluster/health
```

Attendez que `"status"` soit `"green"` avant de continuer. Si l'état est `"yellow"`, c'est normal sur un nœud unique (les réplicas ne peuvent pas être alloués). Dans notre configuration de formation, le statut sera vert car nous avons désactivé les réplicas.

### 2.2 Informations générales du nœud

```bash
curl -s http://localhost:9200/
```

Notez les informations retournées :
- `name` : nom du nœud
- `cluster_name` : nom du cluster
- `version.number` : version d'OpenSearch

### 2.3 Questions de réflexion

- Quel est le nom du cluster par défaut ?
- Combien de nœuds composent votre cluster ?
- Quel est le rôle de ce nœud (`node.roles`) ?

---

## Exercice 3 — Explorer les Cat APIs

Les Cat APIs (Compact And Aligned Text) affichent les informations de manière lisible pour les humains.

### 3.1 Liste des nœuds

```bash
curl -s "http://localhost:9200/_cat/nodes?v"
```

Identifiez : le nom du nœud, son adresse IP, l'utilisation du heap, et son rôle.

### 3.2 Liste des indices

```bash
curl -s "http://localhost:9200/_cat/indices?v"
```

Pour l'instant, seuls les indices système (préfixés par `.`) sont présents. Quels sont-ils ?

### 3.3 Liste des shards

```bash
curl -s "http://localhost:9200/_cat/shards?v"
```

Observez la colonne `state`. Que signifie `STARTED` ?

### 3.4 Toutes les Cat APIs disponibles

```bash
curl -s "http://localhost:9200/_cat"
```

Parcourez la liste. Lesquelles vous semblent les plus utiles pour le monitoring ?

### 3.5 Filtrer et trier

```bash
# Afficher uniquement les indices non-système, triés par taille
curl -s "http://localhost:9200/_cat/indices?v&s=store.size:desc" | grep -v "^\."
```

---

## Exercice 4 — Naviguer dans OpenSearch Dashboards

### 4.1 Accéder à l'interface

Ouvrez votre navigateur et allez sur : **http://localhost:5601**

Si l'interface vous demande des identifiants, entrez :
- Utilisateur : `admin`
- Mot de passe : `Formation@OpenSearch2024!`

### 4.2 Explorer les sections principales

Naviguez dans le menu de gauche et identifiez les sections suivantes :

| Section | Description |
|---------|-------------|
| **Discover** | Exploration interactive des données |
| **Visualize** | Création de graphiques et visualisations |
| **Dashboards** | Tableaux de bord composites |
| **Dev Tools** | Console pour écrire des requêtes API |
| **Stack Management** | Gestion des index, mappings, templates |

### 4.3 Utiliser la Dev Tools Console

1. Cliquez sur **Dev Tools** dans le menu gauche
2. Dans la console, tapez la requête suivante et appuyez sur le bouton "play" (▶) :

```
GET _cluster/health
```

3. Essayez également :

```
GET _cat/nodes?v&format=json
```

```
GET _cat/indices?v&format=json
```

> **Astuce** : La Dev Tools Console est votre meilleur allié pour développer des requêtes. Elle offre l'autocomplétion (Ctrl+Espace) et formate automatiquement le JSON.

### 4.4 Explorer Stack Management

Allez dans **Stack Management > Index Management**. Que voyez-vous ?

---

## Exercice 5 — Modifier la configuration du cluster

### 5.1 Changer le nom du cluster

Arrêtez les conteneurs :

```bash
cd infrastructure/
docker compose down
```

Ouvrez le fichier `infrastructure/docker-compose.yml` dans votre éditeur. Repérez la section `environment` du service `opensearch` et ajoutez la variable :

```yaml
- cluster.name=ecommerce-search
```

### 5.2 Redémarrer et vérifier

```bash
docker compose up -d
```

Attendez que le cluster soit prêt, puis vérifiez :

```
GET /
```

Le champ `cluster_name` doit maintenant afficher `ecommerce-search`.

Vérifiez également avec la Cat API :

```bash
curl -s "http://localhost:9200/_cat/nodes?v&h=name,ip,heap.percent,ram.percent,cpu,load_1m,node.role,master,cluster_manager"
```

### 5.3 Modifier les paramètres de cluster dynamiquement

Certains paramètres peuvent être modifiés sans redémarrage via l'API :

```
PUT /_cluster/settings
{
  "persistent": {
    "action.auto_create_index": "false"
  }
}
```

> **Important** : Remettez ce paramètre à sa valeur par défaut après le test, sinon les TPs suivants échoueront !

```
PUT /_cluster/settings
{
  "persistent": {
    "action.auto_create_index": null
  }
}
```

---

## TP Bonus — Installer OpenSearch sans Docker

Si vous souhaitez comprendre l'installation native (hors Docker) :

### Option 1 : Via archive tar.gz (Linux / macOS)

```bash
# Télécharger OpenSearch 3.6
wget https://artifacts.opensearch.org/releases/bundle/opensearch/3.6.0/opensearch-3.6.0-linux-x64.tar.gz

# Extraire l'archive
tar -xzf opensearch-3.6.0-linux-x64.tar.gz
cd opensearch-3.6.0/

# Configuration minimale dans config/opensearch.yml
cat >> config/opensearch.yml << 'EOF'
cluster.name: ecommerce-search-native
node.name: node-1
network.host: 0.0.0.0
discovery.type: single-node
plugins.security.disabled: true
EOF

# Démarrer OpenSearch
./bin/opensearch
```

### Option 2 : Via package RPM/DEB (Linux)

```bash
# Import de la clé GPG
curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring

# Pour Ubuntu/Debian
echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-3.x.list
sudo apt-get update
sudo apt-get install opensearch=3.6.0
sudo systemctl start opensearch
```

### Paramètres système requis (Linux)

```bash
# vm.max_map_count
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Ulimits
sudo bash -c 'echo "opensearch - nofile 65536" >> /etc/security/limits.conf'
sudo bash -c 'echo "opensearch - nproc 4096" >> /etc/security/limits.conf'
```

---

## Vérification finale

Cochez chaque point avant de passer au TP2 :

- [ ] `docker compose ps` affiche les deux services en état `healthy`
- [ ] `curl http://localhost:9200/_cluster/health` retourne `"status":"green"` ou `"status":"yellow"`
- [ ] `curl http://localhost:9200/` affiche `"cluster_name":"ecommerce-search"`
- [ ] `curl http://localhost:9200/_cat/nodes?v` affiche au moins un nœud
- [ ] L'interface Dashboards est accessible sur http://localhost:5601
- [ ] La Dev Tools Console fonctionne (requête `GET _cluster/health` retourne un résultat)
- [ ] Vous avez remis `action.auto_create_index` à sa valeur par défaut (null)

---

## Récapitulatif des commandes essentielles

| Commande | Description |
|----------|-------------|
| `docker compose up -d` | Démarrer les services en arrière-plan |
| `docker compose down` | Arrêter et supprimer les conteneurs |
| `docker compose ps` | Statut des conteneurs |
| `docker compose logs -f opensearch` | Suivre les logs en temps réel |
| `GET _cluster/health` | Santé du cluster |
| `GET _cat/nodes?v` | Liste des nœuds |
| `GET _cat/indices?v` | Liste des indices |
| `GET _cat/shards?v` | Liste des shards |

---

*Passez au [TP2 — CRUD & API](../tp2-crud-api/README.md) une fois toutes les vérifications validées.*
