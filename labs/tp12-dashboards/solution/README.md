# TP5 — Solution complète : Tableau de bord e-commerce

## Exercice 1 — Création de l'Index Pattern

### Étapes détaillées

**Navigation :**
- Menu hamburger (☰) → Management → Stack Management → Index Patterns → Create index pattern

**Champs à remplir :**

| Champ             | Valeur      |
|-------------------|-------------|
| Index pattern name| `products`  |
| Time field        | `created_at`|

**Capture d'écran attendue :** L'écran "Create index pattern - Step 1 of 2" affiche le champ `products` dans la liste des index existants. Après création, la liste des champs montre 16 champs dont `category.keyword`, `price` (float), `rating` (float), `created_at` (date).

**Vérification depuis l'API :**
```bash
curl -X GET "http://localhost:9200/products/_mapping?pretty"
```

La réponse doit montrer un mapping avec `created_at` de type `date`, `category` de type `text` avec un sous-champ `keyword`, et `price` de type `float`.

---

## Exercice 2 — Exploration avec Discover

### Filtre KQL recommandé

```
category: "Électronique" AND price > 500
```

Ce filtre utilise :
- `category` : recherche plein texte (analysé) sur le champ text
- `price > 500` : filtre de plage sur un champ numérique

**Résultat attendu :** Les smartphones, ordinateurs et TV supérieurs à 500€ apparaissent.

### Autres filtres testés

```
rating >= 4.5 AND stock_quantity > 0
```
Affiche les produits bien notés et disponibles en stock.

```
name: "Samsung" OR brand: "Apple"
```
Affiche les produits Samsung ou Apple (recherche plein texte, insensible à la casse).

### Colonnes recommandées

Cliquez sur ces champs dans le panneau gauche pour les ajouter :
- `name`
- `category`
- `price`
- `rating`
- `stock_quantity`

**Tri :** Cliquez sur l'en-tête `price` puis sur la flèche descendante pour trier par prix décroissant.

### Sauvegarde

Save → Nommez `Produits Électronique > 500€` → Save

---

## Exercice 3 — Création des visualisations

### Visualisation A — Métrique : Nombre total de produits

**Type :** Metric

**Configuration :**
```
Metrics :
  - Agrégation : Count
  - Label personnalisé : "Nombre total de produits"
```

**Capture d'écran attendue :** Un grand nombre affiché en bleu sur fond blanc. Pour notre jeu de données de démonstration, la valeur est entre 1 000 et 10 000 selon les données chargées.

**Sauvegarde :** `Métrique - Nombre de produits`

---

### Visualisation B — Métrique : Prix moyen

**Type :** Metric

**Configuration :**
```
Metrics :
  - Agrégation : Average
  - Field : price
  - Label personnalisé : "Prix moyen (€)"
  - Format : Number, 2 décimales
```

**Capture d'écran attendue :** Un nombre décimal, par exemple `247.83` représentant le prix moyen en euros.

**Sauvegarde :** `Métrique - Prix moyen`

---

### Visualisation C — Camembert : Répartition par catégorie

**Type :** Pie

**Configuration :**
```
Buckets :
  - Split slices
  - Agrégation : Terms
  - Field : category.keyword
  - Order by : Count (descending)
  - Size : 10
Options :
  - Show labels : activé
  - Show legend : activé (position : droite)
```

**Capture d'écran attendue :** Un camembert avec 10 tranches colorées représentant les catégories. La catégorie "Électronique" représente généralement la plus grande part (environ 25-30%).

**Sauvegarde :** `Camembert - Répartition catégories`

---

### Visualisation D — Bar Chart : Top 10 catégories

**Type :** Vertical Bar

**Configuration :**
```
Metrics :
  - Y-axis : Count
  - Label : "Nombre de produits"

Buckets :
  - X-axis
  - Agrégation : Terms
  - Field : category.keyword
  - Order : Descending by Count
  - Size : 10

Options :
  - Show values on chart : activé
  - Rotate labels : 45°
```

**Capture d'écran attendue :** 10 barres verticales de hauteur décroissante, chaque barre représentant une catégorie. Les valeurs s'affichent au-dessus de chaque barre.

**Sauvegarde :** `Bar Chart - Top 10 catégories`

---

### Visualisation E — Line Chart : Prix moyen par tranche

**Type :** Line

**Configuration :**
```
Metrics :
  - Y-axis : Average
  - Field : price
  - Label : "Prix moyen"

Buckets :
  - X-axis
  - Agrégation : Histogram
  - Field : price
  - Minimum interval : 100

Options :
  - Show dots : activé
  - Fill between lines : 0.3
  - Line width : 2
```

**Interprétation :** La courbe monte progressivement. Les tranches 0-100€ ont le plus de produits (pic de densité), les tranches 900-1000€+ ont peu de produits mais des prix moyens élevés.

**Sauvegarde :** `Line Chart - Prix moyen par tranche`

---

### Visualisation F — Data Table : Top 20 produits chers

**Type :** Data Table

**Configuration :**
```
Metrics :
  - Agrégation : Max
  - Field : price
  - Label : "Prix (€)"

Buckets :
  - Split rows
  - Agrégation : Terms
  - Field : name.keyword
  - Order by : metric "Prix (€)" descending
  - Size : 20
```

**Capture d'écran attendue :** Un tableau à 2 colonnes (`name` et `Prix (€)`) avec les 20 produits les plus chers en tête. Les prix sont formatés avec 2 décimales.

**Sauvegarde :** `Table - Top 20 produits chers`

---

### Visualisation G — Coordinate Map (si index stores disponible)

**Prérequis — Créer l'index stores :**

```bash
curl -X PUT "http://localhost:9200/stores" -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "name":     { "type": "keyword" },
      "city":     { "type": "keyword" },
      "location": { "type": "geo_point" },
      "created_at": { "type": "date" }
    }
  }
}'
```

```bash
curl -X POST "http://localhost:9200/stores/_bulk" -H "Content-Type: application/json" -d '
{"index":{"_id":"1"}}
{"name":"Paris Centre","city":"Paris","location":{"lat":48.8566,"lon":2.3522},"created_at":"2025-01-01"}
{"index":{"_id":"2"}}
{"name":"Lyon Confluence","city":"Lyon","location":{"lat":45.7640,"lon":4.8357},"created_at":"2025-01-15"}
{"index":{"_id":"3"}}
{"name":"Marseille Vieux-Port","city":"Marseille","location":{"lat":43.2965,"lon":5.3698},"created_at":"2025-02-01"}
{"index":{"_id":"4"}}
{"name":"Bordeaux Chartrons","city":"Bordeaux","location":{"lat":44.8378,"lon":-0.5792},"created_at":"2025-02-15"}
{"index":{"_id":"5"}}
{"name":"Lille Grand Place","city":"Lille","location":{"lat":50.6292,"lon":3.0573},"created_at":"2025-03-01"}
'
```

**Type de visualisation :** Maps (recommandé dans OpenSearch 2.x+)

**Configuration :**
```
Layer type : Documents
Index pattern : stores
Geospatial field : location
Tooltip : name, city
```

**Sauvegarde :** `Map - Emplacements magasins`

---

## Exercice 4 — Assemblage du tableau de bord

### Layout final recommandé

```
+------------------+------------------+---------------------------+
| Métrique:        | Métrique:        |                           |
| Nb Produits      | Prix Moyen       |   Camembert Catégories    |
| (largeur: 12)    | (largeur: 12)    |   (largeur: 24)           |
+------------------+------------------+---------------------------+
|                                                                  |
|              Bar Chart - Top 10 Catégories                       |
|              (largeur: 48, hauteur: 16)                          |
|                                                                  |
+-----------------------------------+------------------------------+
|                                   |                              |
|   Line Chart - Prix par tranche   |   Table - Top 20 produits   |
|   (largeur: 24)                   |   (largeur: 24)             |
|                                   |                              |
+-----------------------------------+------------------------------+
|                                                                  |
|              Map - Emplacements Magasins                         |
|              (largeur: 48, si disponible)                        |
|                                                                  |
+------------------------------------------------------------------+
```

### Configuration du filtre global

1. **Add filter** → Field: `category.keyword`, Operator: `is`, Value: `Électronique`
2. Toutes les visualisations filtrent simultanément sur la catégorie Électronique
3. Supprimer le filtre : cliquer sur la croix (×) du filtre dans la barre de filtres

### Configuration de la plage temporelle

- Plage : **Last 1 year** (ou sélection personnalisée)
- Rafraîchissement automatique : **Every 30 seconds** pour les données en temps réel

### Sauvegarde finale

Save → Titre : `Tableau de bord E-commerce` → Cocher `Store time with dashboard` → Save

---

## Bonus — Import/Export des Saved Objects

### Export depuis l'API REST

```bash
curl -X POST "http://localhost:5601/api/saved_objects/_export" \
  -H "Content-Type: application/json" \
  -H "osd-xsrf: true" \
  -d '{
    "type": "dashboard",
    "includeReferencesDeep": true
  }' -o mon-dashboard-export.ndjson
```

### Import depuis l'API REST

```bash
curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "osd-xsrf: true" \
  -F "file=@saved-objects-export.ndjson"
```

**Résultat attendu :** La réponse JSON indique `"success": true` et liste les objets importés :
- `index-pattern` : `products`
- `visualization` : `Pie - Catégories (import)`, `Métrique - Nombre de produits (import)`, `Bar Chart - Top 10 catégories (import)`
- `dashboard` : `Dashboard E-commerce (import)`

---

## Points clés à retenir

1. **Index pattern vs index** : L'index pattern est une vue Dashboards sur un ou plusieurs index OpenSearch. Il peut utiliser des wildcards (`products-*`).

2. **Champs `.keyword` pour les agrégations** : Toujours utiliser `category.keyword` (pas `category`) pour les agrégations Terms — les champs `text` ne sont pas agrégables par défaut.

3. **Filtres globaux vs locaux** : Les filtres dans la barre du haut s'appliquent à toutes les visualisations du dashboard. Les filtres dans une visualisation individuelle ne s'appliquent qu'à elle.

4. **KQL vs DQL** : KQL (Kibana Query Language) est disponible dans OpenSearch Dashboards. C'est un langage simple pour filtrer les documents sans écrire de Query DSL complet.

5. **Sélection du champ de date** : Le champ `created_at` doit être de type `date` dans le mapping pour fonctionner comme time field dans Dashboards.
