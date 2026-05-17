# TP10 — Tableau de bord e-commerce avec OpenSearch Dashboards

## Informations générales

| Paramètre  | Valeur                          |
|------------|---------------------------------|
| Durée      | 45 minutes                      |
| Difficulté | Intermédiaire                   |
| Prérequis  | TP9 terminé (agrégations complètes requises) |
| URL        | http://localhost:5601           |

## Objectif

Créer un tableau de bord e-commerce complet dans OpenSearch Dashboards permettant d'analyser les produits, les catégories et les performances commerciales de notre boutique en ligne.

## Contexte

Notre équipe de direction souhaite disposer d'un tableau de bord analytique centralisé pour piloter l'activité e-commerce. Vous allez construire ce tableau de bord de bout en bout : de la configuration de l'index pattern jusqu'à l'assemblage final des visualisations.

## Prérequis techniques

- TP4 terminé et données chargées dans l'index `products`
- OpenSearch Dashboards accessible sur http://localhost:5601
- OpenSearch accessible sur http://localhost:9200
- Navigateur web moderne (Chrome ou Firefox recommandé)

---

## Exercice 1 — Créer l'Index Pattern pour `products`

### 1.1 Accéder à la gestion des index patterns

1. Ouvrez http://localhost:5601 dans votre navigateur
2. Dans le menu de gauche, cliquez sur l'icône **hamburger** (☰) pour ouvrir la navigation
3. Allez dans **Management** → **Stack Management**
4. Dans la section **Kibana / Dashboards**, cliquez sur **Index Patterns**

### 1.2 Créer l'index pattern

1. Cliquez sur le bouton **Create index pattern**
2. Dans le champ **Index pattern name**, tapez : `products`
3. Dashboards affiche la liste des index correspondants — vérifiez que `products` apparaît bien
4. Cliquez sur **Next step**
5. Dans le menu déroulant **Time field**, sélectionnez : `created_at`
6. Cliquez sur **Create index pattern**

### 1.3 Explorer les champs disponibles

Après la création, explorez la liste des champs :
- Repérez les champs de type `keyword` (ex. `category.keyword`, `brand.keyword`)
- Repérez les champs de type `text` (ex. `name`, `description`)
- Repérez les champs numériques : `price`, `stock_quantity`, `rating`
- Repérez le champ date : `created_at`

> **Astuce** : Les champs suffixés `.keyword` sont utilisés pour les agrégations et les tris.

---

## Exercice 2 — Explorer les données avec Discover

### 2.1 Ouvrir Discover

1. Dans le menu de gauche, cliquez sur **Discover**
2. Sélectionnez l'index pattern `products` si ce n'est pas déjà fait (menu déroulant en haut à gauche)
3. Ajustez la plage temporelle en haut à droite — essayez **Last 1 year** ou **Last 5 years**

### 2.2 Appliquer des filtres KQL

Dans la barre de recherche en haut de Discover, tapez les filtres suivants (un par un) et observez les résultats :

**Filtre 1 — Produits électroniques chers :**
```
category: "Électronique" AND price > 500
```

**Filtre 2 — Produits bien notés en stock :**
```
rating >= 4.5 AND stock_quantity > 0
```

**Filtre 3 — Recherche textuelle :**
```
name: "Samsung" OR brand: "Apple"
```

**Filtre 4 — Combinaison avancée :**
```
category: "Vêtements" AND price < 50 AND rating > 3
```

### 2.3 Personnaliser les colonnes

1. Dans le panneau de gauche, cliquez sur les champs `name`, `category`, `price`, `rating` pour les ajouter comme colonnes
2. Réorganisez les colonnes selon vos préférences
3. Triez par `price` décroissant en cliquant sur l'en-tête de colonne

### 2.4 Sauvegarder la recherche

1. Cliquez sur **Save** en haut de la page
2. Nommez la recherche : `Produits Électronique > 500€`
3. Cliquez sur **Save**

---

## Exercice 3 — Créer les visualisations

### Visualisation A — Métrique : Nombre total de produits

1. Allez dans **Visualize Library** (menu gauche → Visualize)
2. Cliquez sur **Create visualization**
3. Sélectionnez le type **Metric**
4. Choisissez l'index pattern `products`
5. Dans le panneau de gauche sous **Metrics** :
   - Metric : `Count`
   - Label : `Nombre total de produits`
6. Cliquez sur **Update** (bouton bleu en bas)
7. Sauvegardez sous le nom : `Métrique - Nombre de produits`

### Visualisation B — Métrique : Prix moyen

1. Créez une nouvelle visualisation **Metric**
2. Dans **Metrics** :
   - Cliquez sur **Add metric**
   - Sélectionnez l'agrégation : `Average`
   - Field : `price`
   - Label : `Prix moyen (€)`
3. Dans les options d'affichage, définissez le format à 2 décimales
4. Sauvegardez sous : `Métrique - Prix moyen`

### Visualisation C — Camembert : Répartition par catégorie

1. Créez une nouvelle visualisation **Pie**
2. Sous **Buckets** :
   - Cliquez sur **Add bucket** → **Split slices**
   - Agrégation : `Terms`
   - Field : `category.keyword`
   - Size : `10`
   - Order by : `Count`
3. Cliquez sur **Update**
4. Dans **Options** (onglet en haut), activez **Show labels**
5. Sauvegardez sous : `Camembert - Répartition catégories`

### Visualisation D — Bar Chart : Top 10 catégories par nombre de produits

1. Créez une nouvelle visualisation **Vertical Bar**
2. Sous **Metrics** :
   - Y-axis : `Count`
3. Sous **Buckets** :
   - **X-axis** : Agrégation `Terms`, Field `category.keyword`, Size `10`, Order `Descending by Count`
4. Dans **Options**, activez **Show values on chart**
5. Sauvegardez sous : `Bar Chart - Top 10 catégories`

### Visualisation E — Line Chart : Prix moyen par tranche de prix

1. Créez une nouvelle visualisation **Line**
2. Sous **Metrics** :
   - Y-axis : Agrégation `Average`, Field `price`, Label `Prix moyen`
3. Sous **Buckets** :
   - **X-axis** : Agrégation `Histogram`, Field `price`, Minimum interval `100`
4. Dans **Options**, activez **Show dots** et **Fill lines**
5. Sauvegardez sous : `Line Chart - Prix moyen par tranche`

### Visualisation F — Data Table : Top 20 produits les plus chers

1. Créez une nouvelle visualisation **Data Table**
2. Sous **Metrics** :
   - Metric : `Max`, Field : `price`, Label : `Prix maximum (€)`
3. Sous **Buckets** :
   - **Split rows** : Agrégation `Terms`, Field `name.keyword`, Size `20`, Order `Descending by metric: Prix maximum`
4. Sauvegardez sous : `Table - Top 20 produits chers`

### Visualisation G — Coordinate Map : Emplacements des magasins

> Cette visualisation utilise l'index `stores` qui doit être créé.

1. Créez l'index pattern `stores` avec le champ de date `created_at`
2. Créez une nouvelle visualisation **Coordinate Map** (ou **Maps**)
3. Sous **Metrics** :
   - Agrégation : `Count`
4. Sous **Buckets** :
   - Agrégation : `Geohash`, Field : `location`, Precision : `3`
5. Sauvegardez sous : `Map - Emplacements magasins`

---

## Exercice 4 — Assembler le tableau de bord complet

### 4.1 Créer le dashboard

1. Dans le menu gauche, cliquez sur **Dashboard**
2. Cliquez sur **Create dashboard**
3. Cliquez sur **Add** (ou **Add an existing**) pour ajouter les visualisations

### 4.2 Ajouter les visualisations

Ajoutez dans cet ordre :
1. `Métrique - Nombre de produits`
2. `Métrique - Prix moyen`
3. `Camembert - Répartition catégories`
4. `Bar Chart - Top 10 catégories`
5. `Line Chart - Prix moyen par tranche`
6. `Table - Top 20 produits chers`
7. `Map - Emplacements magasins` (si disponible)

### 4.3 Organiser le layout

1. Faites glisser les panneaux pour les réorganiser
2. Redimensionnez les visualisations en tirant le coin inférieur droit
3. Disposition suggérée :
   - Ligne 1 : Les 2 métriques côte à côte (petits panneaux)
   - Ligne 2 : Camembert (gauche) + Bar Chart (droite)
   - Ligne 3 : Line Chart (pleine largeur)
   - Ligne 4 : Data Table + Map côte à côte

### 4.4 Configurer les filtres globaux

1. Cliquez sur **Add filter** dans la barre de filtres en haut
2. Ajoutez un filtre : `category.keyword` `is` `Électronique`
3. Observez que toutes les visualisations se mettent à jour simultanément
4. Retirez le filtre pour revenir à la vue complète

### 4.5 Configurer le sélecteur de plage temporelle

1. En haut à droite, cliquez sur le sélecteur de plage temporelle
2. Sélectionnez **Last 1 year**
3. Activez le rafraîchissement automatique : **Every 30 seconds**
4. Observez le comportement du dashboard

### 4.6 Sauvegarder le dashboard

1. Cliquez sur **Save** en haut à droite
2. Nommez le dashboard : `Tableau de bord E-commerce`
3. Cochez **Store time with dashboard** pour mémoriser la plage temporelle
4. Cliquez sur **Save**

---

## TP Bonus — Import/Export d'objets sauvegardés

### Exporter le dashboard

1. Allez dans **Management** → **Stack Management** → **Saved Objects**
2. Cochez le dashboard `Tableau de bord E-commerce`
3. Cliquez sur **Export**
4. Choisissez **Include related objects** pour inclure toutes les visualisations
5. Téléchargez le fichier `export.ndjson`

### Importer un dashboard existant

1. Dans **Saved Objects**, cliquez sur **Import**
2. Glissez-déposez le fichier `saved-objects-export.ndjson` fourni dans ce répertoire
3. Choisissez **Automatically overwrite conflicts**
4. Cliquez sur **Import**
5. Vérifiez que les objets `products index pattern`, `Pie - Catégories (import)` et `Dashboard E-commerce (import)` apparaissent bien

### Tester le dashboard importé

1. Allez dans **Dashboard**
2. Ouvrez `Dashboard E-commerce (import)`
3. Vérifiez que la visualisation s'affiche correctement

---

## Vérification finale

A la fin de ce TP, vous devez avoir :

- [ ] L'index pattern `products` créé avec le champ de date `created_at`
- [ ] Une recherche sauvegardée dans Discover avec filtre KQL
- [ ] 6 visualisations créées (Metric x2, Pie, Bar, Line, Table)
- [ ] Un dashboard assemblé avec toutes les visualisations
- [ ] Les filtres globaux testés
- [ ] Le sélecteur de plage temporelle configuré
- [ ] (Bonus) Import/export de saved objects réalisé

---

## Ressources

- [Documentation OpenSearch Dashboards](https://opensearch.org/docs/latest/dashboards/)
- [Guide KQL (Kibana Query Language)](https://opensearch.org/docs/latest/dashboards/dql/)
- [Types de visualisations](https://opensearch.org/docs/latest/dashboards/visualize/viz-index/)

*Passez au [TP11 — Reindex + ISM](../tp11-reindex-ism/README.md)*
