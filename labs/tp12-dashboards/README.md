# TP12 — Dashboard "Product Analytics" sur l'index products

## Informations générales

| Paramètre  | Valeur                                                                         |
|------------|--------------------------------------------------------------------------------|
| Durée      | 40 minutes                                                                     |
| Difficulté | Intermédiaire                                                                  |
| Prérequis  | Index `products` indexé depuis le Jour 2 (1000+ documents), OpenSearch Dashboards sur http://localhost:5601 |

## Objectif

Construire un dashboard analytique complet "Product Analytics" dans OpenSearch Dashboards en utilisant Lens pour toutes les visualisations. Vous allez créer la Data View, explorer les données avec Discover et DQL, puis assembler le dashboard final avec un control interactif.

---

## Exercice 1 — Créer la Data View pour `products`

### 1.1 Accéder à la gestion des Data Views

1. Ouvrez http://localhost:5601
2. Dans le menu de gauche, cliquez sur l'icône hamburger (☰)
3. Allez dans **Management** → **Stack Management**
4. Dans la section **Dashboards Management**, cliquez sur **Data Views**

### 1.2 Créer la Data View

1. Cliquez sur **Create data view**
2. Dans le champ **Name**, tapez : `products`
3. Dans le champ **Index pattern**, tapez : `products`
4. Dashboards affiche la liste des index correspondants — vérifiez que `products` apparaît bien
5. Dans le menu déroulant **Timestamp field**, sélectionnez : `indexed_at` (ou `created_at` si disponible)
6. Cliquez sur **Save data view to OpenSearch Dashboards**

### 1.3 Explorer les champs disponibles

Après la création, parcourez la liste des champs :
- Champs de type `keyword` : `category.keyword`, `brand.keyword`, `name.keyword`
- Champs numériques : `price`, `stock_quantity`, `rating`
- Champ date : `indexed_at` ou `created_at`

> Les champs suffixés `.keyword` sont utilisés pour les agrégations et les tris dans Lens.

---

## Exercice 2 — Explorer les données avec Discover + DQL

### 2.1 Ouvrir Discover

1. Dans le menu de gauche, cliquez sur **Discover**
2. Sélectionnez la Data View `products` (menu déroulant en haut à gauche)
3. Ajustez la plage temporelle — essayez **Last 1 year** ou **Last 5 years**

### 2.2 Appliquer des filtres DQL

Dans la barre de recherche en haut de Discover, testez les filtres suivants :

**Filtre 1 — Produits électroniques :**
```
category.keyword: "Electronics"
```

**Filtre 2 — Produits dans une fourchette de prix :**
```
price >= 100 AND price <= 500
```

**Filtre 3 — Recherche textuelle :**
```
name: "laptop" OR name: "phone"
```

**Filtre 4 — Combinaison avancée :**
```
category.keyword: "Electronics" AND price < 200 AND rating > 4
```

### 2.3 Sauvegarder la recherche

1. Cliquez sur **Save** en haut de la page
2. Nommez la recherche : `Electronics < 200€ bien notés`
3. Cliquez sur **Save**

---

## Exercice 3 — Créer les visualisations Lens

Accédez à **Visualize Library** → **Create visualization** et choisissez **Lens** pour chaque visualisation.

### Visualisation A — Donut "Répartition par catégorie"

1. Dans Lens, sélectionnez le type de graphique **Donut** (icône en haut à droite)
2. Glissez le champ `category.keyword` sur la zone **Slice by**
   - Agrégation : `Top values`
   - Size : `10`
3. Glissez `Records` (ou laissez le défaut Count) sur la zone **Size by**
4. Dans les options du panneau : activez **Show values**
5. Titre : `Répartition par catégorie`
6. Sauvegardez sous : `Donut - Répartition par catégorie`

### Visualisation B — Bar Chart "Prix moyen par catégorie"

1. Dans Lens, sélectionnez le type **Bar vertical**
2. Axe X : glissez `category.keyword` → agrégation `Top values`, Size `10`
3. Axe Y : glissez `price` → agrégation `Average`
4. Titre : `Prix moyen par catégorie`
5. Sauvegardez sous : `Bar - Prix moyen par catégorie`

### Visualisation C — Métriques "Total produits" et "Prix moyen global"

1. Dans Lens, sélectionnez le type **Metric**
2. Ajoutez une première métrique :
   - Agrégation : `Count`
   - Label : `Total produits`
3. Cliquez sur **Add layer** → **Add metric** pour ajouter une deuxième valeur :
   - Champ : `price`, Agrégation : `Average`
   - Label : `Prix moyen global`
4. Titre : `KPIs produits`
5. Sauvegardez sous : `Metric - KPIs produits`

### Visualisation D — Data Table "Top 10 produits les plus chers"

1. Dans Lens, sélectionnez le type **Table**
2. Ajoutez une colonne de découpage (row) :
   - Champ : `name.keyword`, Agrégation : `Top values`, Size : `10`
   - Tri : par valeur de métrique décroissant
3. Ajoutez une métrique :
   - Champ : `price`, Agrégation : `Max`
   - Label : `Prix maximum`
4. Titre : `Top 10 produits les plus chers`
5. Sauvegardez sous : `Table - Top 10 produits chers`

---

## Exercice 4 — Assembler le dashboard "Product Analytics"

### 4.1 Créer le dashboard

1. Dans le menu gauche, cliquez sur **Dashboard**
2. Cliquez sur **Create dashboard**

### 4.2 Ajouter les visualisations

Cliquez sur **Add** → **Add from library** et ajoutez :
1. `Donut - Répartition par catégorie`
2. `Bar - Prix moyen par catégorie`
3. `Metric - KPIs produits`
4. `Table - Top 10 produits chers`

### 4.3 Ajouter un Control interactif

1. Cliquez sur **Add** → **Add a panel** → **Controls**
2. Choisissez **Options list**
3. Configurez :
   - Data view : `products`
   - Field : `category.keyword`
   - Label : `Filtrer par catégorie`
4. Cliquez sur **Save and close**

### 4.4 Organiser le layout

Disposition suggérée :
- Ligne 1 : Metric KPIs (petite largeur, pleine hauteur réduite)
- Ligne 2 : Donut (gauche, 50%) + Bar Chart (droite, 50%)
- Ligne 3 : Data Table (pleine largeur)

Testez le Control "Filtrer par catégorie" — toutes les visualisations doivent se mettre à jour.

### 4.5 Sauvegarder le dashboard

1. Cliquez sur **Save** en haut à droite
2. Nommez le dashboard : `Product Analytics`
3. Cliquez sur **Save**

---

## Exercice Bonus — Visualisations avancées

### Bonus A — Line Chart "Produits indexés par mois"

1. Dans Lens, créez un graphique **Line**
2. Axe X : champ date (`indexed_at` ou `created_at`) → agrégation `Date histogram`, interval `1 month`
3. Axe Y : `Count`
4. Titre : `Produits indexés par mois`
5. Ajoutez au dashboard.

### Bonus B — Gauge "% produits en stock"

1. Dans Lens, créez un graphique **Gauge**
2. Métrique : expression `Filters`
   - Filtre A : `stock_quantity > 0` (label : `En stock`)
   - Divisé par Count total pour obtenir un pourcentage
3. Sinon : utilisez une métrique `Count` avec filtre DQL `stock_quantity > 0` et comparez manuellement
4. Titre : `Produits en stock`

---

## Vérification finale

- [ ] Data View `products` créée avec champ date (`indexed_at` ou `created_at`)
- [ ] Filtres DQL testés dans Discover (catégorie, prix, texte)
- [ ] Recherche Discover sauvegardée
- [ ] Visualisation A : Donut "Répartition par catégorie" créée avec Lens
- [ ] Visualisation B : Bar Chart "Prix moyen par catégorie" créée avec Lens
- [ ] Visualisation C : Metric "Total produits" + "Prix moyen global" créée avec Lens
- [ ] Visualisation D : Data Table "Top 10 produits les plus chers" créée avec Lens
- [ ] Dashboard "Product Analytics" assemblé avec les 4 visualisations
- [ ] Control Options List sur `category.keyword` ajouté et fonctionnel
- [ ] (Bonus) Line Chart "Produits indexés par mois" créé et ajouté
- [ ] (Bonus) Gauge ou Metric "% produits en stock" créé et ajouté

---

## Ressources

- [Documentation OpenSearch Dashboards](https://opensearch.org/docs/latest/dashboards/)
- [Guide DQL (Dashboards Query Language)](https://opensearch.org/docs/latest/dashboards/dql/)
- [Lens — éditeur de visualisations](https://opensearch.org/docs/latest/dashboards/visualize/lens/)
- [Controls dans les dashboards](https://opensearch.org/docs/latest/dashboards/controls/index/)

*Suite : [TP13 — ISM, Aliases & Snapshots](../tp13-reindex-ism/README.md)*
