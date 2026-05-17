# TP3 — CRUD & API

## Objectif

Maîtriser les opérations CRUD (Create, Read, Update, Delete) et le Bulk API d'OpenSearch pour construire la base de notre catalogue produits e-commerce.

## Prérequis

- TP1 terminé et validé
- Cluster OpenSearch en cours d'exécution (`docker compose ps` affiche `healthy`)
- `curl` disponible dans le terminal

## Durée estimée

45 minutes

## Contexte fil rouge

Notre moteur de recherche e-commerce a besoin d'un catalogue produits. Dans ce TP, vous allez :
1. Créer l'index `products` avec un mapping précis adapté à la recherche e-commerce
2. Indexer manuellement quelques produits pour comprendre la structure
3. Maîtriser les opérations de lecture, mise à jour et suppression
4. Charger en masse plus de 1000 produits via le Bulk API — la méthode efficace en production

---

## Structure des données produit

Voici la structure d'un produit de notre catalogue :

```json
{
  "name": "Smartphone XPhone Pro 256Go",
  "description": "Smartphone haut de gamme avec écran AMOLED 6.7 pouces...",
  "category": "Électronique",
  "sub_category": "Smartphones",
  "brand": "TechBrand",
  "price": 899.99,
  "original_price": 1099.99,
  "currency": "EUR",
  "in_stock": true,
  "stock_quantity": 42,
  "rating": 4.5,
  "reviews_count": 1234,
  "tags": ["smartphone", "5G", "AMOLED", "256Go"],
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-03-20T14:00:00Z",
  "seller": "TechShop",
  "weight_kg": 0.195,
  "color": "Noir"
}
```

---

## Exercice 1 — Créer l'index `products` avec un mapping explicite

Un mapping explicite est essentiel en production : il garantit que chaque champ est analysé et stocké de la bonne façon.

### 1.1 Comprendre les types de champs

Avant de créer le mapping, comprenez les types utilisés :

| Type OpenSearch | Utilisation |
|-----------------|-------------|
| `text` | Texte analysé pour la recherche full-text (name, description) |
| `keyword` | Texte exact, non analysé (category, brand, color) — utile pour les filtres et agrégations |
| `float` / `double` | Nombres décimaux (price, rating, weight_kg) |
| `integer` | Nombres entiers (stock_quantity, reviews_count) |
| `boolean` | Vrai/Faux (in_stock) |
| `date` | Dates et timestamps (created_at, updated_at) |

### 1.2 Créer le mapping

Utilisez le script `exercices.sh` pour créer l'index, ou exécutez directement depuis le Dev Console :

```
PUT /products
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "name": { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
      "description": { "type": "text" },
      "category": { "type": "keyword" },
      "sub_category": { "type": "keyword" },
      "brand": { "type": "keyword" },
      "price": { "type": "float" },
      "original_price": { "type": "float" },
      "currency": { "type": "keyword" },
      "in_stock": { "type": "boolean" },
      "stock_quantity": { "type": "integer" },
      "rating": { "type": "float" },
      "reviews_count": { "type": "integer" },
      "tags": { "type": "keyword" },
      "created_at": { "type": "date" },
      "updated_at": { "type": "date" },
      "seller": { "type": "keyword" },
      "weight_kg": { "type": "float" },
      "color": { "type": "keyword" }
    }
  }
}
```

**Réponse attendue :**
```json
{
    "acknowledged": true,
    "shards_acknowledged": true,
    "index": "products"
}
```

### 1.3 Vérifier le mapping créé

```
GET /products/_mapping
```

> **Pourquoi `name.keyword` en plus de `name` ?** Le champ `name` est de type `text` (analysé, pour la recherche full-text). Le sous-champ `name.keyword` est de type `keyword` (non analysé, pour les tris et agrégations exactes). Cette combinaison est très courante.

---

## Exercice 2 — Indexer manuellement 5 produits

### 2.1 Indexer votre premier produit

Complétez le TODO dans `exercices.sh` pour indexer un smartphone.

Structure d'un PUT d'indexation :
```
PUT /products/_doc/{id}
```

Indexez les 5 produits suivants (un par un, avec des IDs de 1 à 5) :

**Produit 1 — Smartphone**
```json
{
  "name": "Smartphone XPhone Pro 256Go",
  "description": "Smartphone haut de gamme avec écran AMOLED 6.7 pouces, processeur octa-core et triple capteur photo 108MP",
  "category": "Électronique",
  "sub_category": "Smartphones",
  "brand": "TechBrand",
  "price": 899.99,
  "original_price": 1099.99,
  "currency": "EUR",
  "in_stock": true,
  "stock_quantity": 42,
  "rating": 4.5,
  "reviews_count": 1234,
  "tags": ["smartphone", "5G", "AMOLED", "256Go"],
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-03-20T14:00:00Z",
  "seller": "TechShop",
  "weight_kg": 0.195,
  "color": "Noir"
}
```

**Produit 2 — Ordinateur portable**
```json
{
  "name": "Ordinateur Portable UltraBook 15",
  "description": "Laptop ultra-fin 15 pouces, Intel Core i7, 16Go RAM, SSD 512Go, idéal pour les professionnels",
  "category": "Électronique",
  "sub_category": "Ordinateurs portables",
  "brand": "CompuPro",
  "price": 1299.00,
  "original_price": 1499.00,
  "currency": "EUR",
  "in_stock": true,
  "stock_quantity": 15,
  "rating": 4.3,
  "reviews_count": 567,
  "tags": ["laptop", "i7", "SSD", "ultrabook"],
  "created_at": "2024-02-01T09:00:00Z",
  "updated_at": "2024-03-15T11:00:00Z",
  "seller": "InfoStore",
  "weight_kg": 1.8,
  "color": "Argent"
}
```

**Produit 3 — Casque audio**
```json
{
  "name": "Casque Audio Sans Fil SoundMax",
  "description": "Casque Bluetooth avec réduction de bruit active, autonomie 30h, recharge rapide USB-C",
  "category": "Électronique",
  "sub_category": "Audio",
  "brand": "SoundMax",
  "price": 199.99,
  "original_price": 249.99,
  "currency": "EUR",
  "in_stock": true,
  "stock_quantity": 89,
  "rating": 4.7,
  "reviews_count": 2345,
  "tags": ["casque", "bluetooth", "reduction-bruit", "sans-fil"],
  "created_at": "2024-01-20T14:00:00Z",
  "updated_at": "2024-03-10T09:30:00Z",
  "seller": "AudioWorld",
  "weight_kg": 0.285,
  "color": "Blanc"
}
```

**Produit 4 — Livre**
```json
{
  "name": "Guide complet du Machine Learning",
  "description": "Apprentissage du Machine Learning de A à Z, avec exemples pratiques en Python et TensorFlow",
  "category": "Livres",
  "sub_category": "Informatique",
  "brand": "ÉditionsData",
  "price": 39.90,
  "original_price": 39.90,
  "currency": "EUR",
  "in_stock": true,
  "stock_quantity": 200,
  "rating": 4.6,
  "reviews_count": 445,
  "tags": ["machine-learning", "python", "ia", "données"],
  "created_at": "2023-09-01T00:00:00Z",
  "updated_at": "2023-09-01T00:00:00Z",
  "seller": "LibraireNet",
  "weight_kg": 0.95,
  "color": "N/A"
}
```

**Produit 5 — Montre connectée**
```json
{
  "name": "Montre Connectée FitWatch Ultra",
  "description": "Smartwatch avec GPS intégré, suivi cardiaque continu, étanche 50m, autonomie 7 jours",
  "category": "Montres & Accessoires",
  "sub_category": "Montres connectées",
  "brand": "FitTech",
  "price": 349.00,
  "original_price": 399.00,
  "currency": "EUR",
  "in_stock": false,
  "stock_quantity": 0,
  "rating": 4.4,
  "reviews_count": 892,
  "tags": ["smartwatch", "GPS", "fitness", "etanche"],
  "created_at": "2024-03-01T00:00:00Z",
  "updated_at": "2024-03-18T16:00:00Z",
  "seller": "SportElec",
  "weight_kg": 0.042,
  "color": "Bleu"
}
```

### 2.2 Forcer le rafraîchissement

Après les indexations, forcez le rafraîchissement pour que les documents soient immédiatement visibles :

```
POST /products/_refresh
```

---

## Exercice 3 — Lire, mettre à jour, supprimer

### 3.1 Lire un document par son ID

Complétez le TODO dans `exercices.sh` pour récupérer le produit ID 1 (smartphone).

Structure :
```
GET /products/_doc/{id}
```

Observez la réponse : que contiennent les champs `_index`, `_id`, `_version`, `_source` ?

### 3.2 Vérifier l'existence sans récupérer le document

```bash
curl -s -I "http://localhost:9200/products/_doc/1"
```

Le code HTTP 200 indique que le document existe, 404 qu'il n'existe pas.

### 3.3 Mettre à jour un champ (Update partiel)

Complétez le TODO dans `exercices.sh` pour mettre à jour le prix du smartphone à 799.99€.

Structure :
```
POST /products/_update/{id}
{
  "doc": { "champ": "nouvelle_valeur" }
}
```

> **Différence entre PUT et POST _update** :
> - `PUT /products/_doc/1` : remplace le document entier
> - `POST /products/_update/1` : met à jour seulement les champs spécifiés (merge partiel)

### 3.4 Mettre à jour avec un script Painless

OpenSearch permet des mises à jour scriptées. Appliquez une remise de 10% sur le prix :

```
POST /products/_update/1
{
  "script": {
    "source": "ctx._source.price = Math.round(ctx._source.price * 0.9 * 100) / 100.0",
    "lang": "painless"
  }
}
```

### 3.5 Supprimer un document

Complétez le TODO dans `exercices.sh` pour supprimer le produit ID 5 (montre connectée — en rupture de stock).

Structure :
```
DELETE /products/_doc/{id}
```

Vérifiez qu'il n'existe plus :
```
GET /products/_doc/5
```

---

## Exercice 4 — Charger le catalogue via Bulk API

Le Bulk API permet d'indexer des milliers de documents en une seule requête HTTP — essentiel pour les performances en production.

### 4.1 Format du Bulk API

Le format NDJSON (Newline-Delimited JSON) du Bulk API est particulier :
```
{"index": {"_index": "products", "_id": "100"}}
{"name": "Produit 100", "price": 29.99, ...}
{"index": {"_index": "products", "_id": "101"}}
{"name": "Produit 101", "price": 49.99, ...}
```

Chaque document est précédé d'une ligne d'action. Les paires de lignes (action + document) doivent être séparées par des retours à la ligne `\n`, y compris à la fin.

### 4.2 Charger le fichier products-bulk.ndjson

Le fichier `data/products-bulk.ndjson` contient plus de 1000 produits. Chargez-les :

> **Note** : Le chargement de fichiers NDJSON se fait via curl, pas depuis le Dev Console.

```bash
curl -s -X POST "http://localhost:9200/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @../../data/products-bulk.ndjson
```

> **Note** : `--data-binary` est crucial (à la place de `-d`) pour préserver les retours à la ligne dans le fichier NDJSON.

### 4.3 Vérifier la réponse Bulk

La réponse contient le champ `errors` (true/false) et `items` (résultat pour chaque document).

Vérifiez que `errors` est `false` dans la réponse.

---

## Exercice 5 — Bonnes pratiques & antipatterns

### 5.1 Antipattern : supprimer un document individuel est coûteux

Dans OpenSearch, supprimer un document individuel ne libère pas immédiatement l'espace disque. Le document est marqué comme supprimé ("tombstone") et l'espace n'est récupéré qu'après un merge de segment Lucene.

```
# À ÉVITER en production pour de gros volumes :
DELETE /products/_doc/1

# PRÉFÉRER pour supprimer plusieurs documents selon un critère :
POST /products/_delete_by_query
{
  "query": { "term": { "in_stock": false } }
}
```

**Règle** : Pour supprimer un index entier (ex. rotation de logs), supprimez l'index, pas les documents un par un.

### 5.2 Antipattern : wildcard en début de terme

Évitez les wildcards au début d'un terme — ils forcent un scan complet de l'index inversé :

```
# MAUVAISE pratique — scan complet, très lent :
GET /products/_search
{
  "query": { "wildcard": { "name": { "value": "*phone" } } }
}
```

```
# BONNE pratique — prefix query ou n-grams à l'indexation :
GET /products/_search
{
  "query": { "prefix": { "name.keyword": { "value": "Smart" } } }
}
```

### 5.3 Bonne pratique : `_source` filtering pour réduire la bande passante

```
GET /products/_search
{
  "_source": ["name", "price", "category", "in_stock"],
  "query": { "match_all": {} },
  "size": 5
}
```

> **Règle** : En production, ne retournez jamais les grands champs (`description`, `images`...) si vous n'en avez pas besoin dans l'affichage.

### 5.4 Bonne pratique : Bulk API et `refresh_interval`

Pour un chargement massif de données, désactivez le refresh automatique pendant l'import :

```
# Désactiver le refresh pendant le chargement
PUT /products/_settings
{
  "index": { "refresh_interval": "-1", "number_of_replicas": 0 }
}
```

> **Note** : Le chargement de fichiers NDJSON se fait via curl, pas depuis le Dev Console.

```bash
# Charger les données via Bulk API
curl -s -X POST "http://localhost:9200/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @../../data/products-bulk.ndjson
```

```
# Réactiver le refresh
PUT /products/_settings
{
  "index": { "refresh_interval": "1s", "number_of_replicas": 1 }
}
```

> **Règle** : Toujours utiliser Bulk API pour > 100 documents. Avec `refresh_interval=-1` et `replicas=0` pendant le chargement, vous pouvez multiplier la vitesse d'indexation par 5 à 10.

---

## Exercice 6 — Vérifier le chargement

### 5.1 Compter les documents

```bash
curl -s "http://localhost:9200/_cat/indices/products?v"
```

Vérifiez la colonne `docs.count` : vous devriez avoir 1004 documents (4 manuels + 1000 du bulk).

### 5.2 Recherche de vérification

```
GET /products/_search
{
  "query": { "match_all": {} },
  "size": 5
}
```

### 5.3 Statistiques de l'index

```
GET /products/_stats
```

### 5.4 Récapitulatif du catalogue

Vérifiez rapidement la distribution des catégories :

```
GET /products/_search
{
  "size": 0,
  "aggs": {
    "categories": {
      "terms": { "field": "category", "size": 20 }
    }
  }
}
```

---

## TP Bonus — Générer 5000 produits aléatoires

### Script Bash (simplifié)

```bash
#!/bin/bash
# Génère 100 produits rapidement pour tester

OUTPUT="products-quick-100.ndjson"
> "$OUTPUT"

CATEGORIES=("Électronique" "Vêtements" "Maison" "Livres" "Sports")
BRANDS=("BrandA" "BrandB" "BrandC" "BrandD")

for i in $(seq 1 100); do
  ID=$((5000 + i))
  CAT="${CATEGORIES[$((RANDOM % ${#CATEGORIES[@]}))]}"
  BRAND="${BRANDS[$((RANDOM % ${#BRANDS[@]}))]}"
  PRICE=$(echo "scale=2; $RANDOM % 1000 + 10" | bc)
  echo "{\"index\":{\"_index\":\"products\",\"_id\":\"$ID\"}}" >> "$OUTPUT"
  echo "{\"name\":\"Produit $i\",\"category\":\"$CAT\",\"brand\":\"$BRAND\",\"price\":$PRICE,\"in_stock\":true,\"currency\":\"EUR\",\"rating\":4.0,\"reviews_count\":100,\"stock_quantity\":50}" >> "$OUTPUT"
done

echo "100 produits générés dans $OUTPUT"
```

---

## Vérification finale

Cochez chaque point avant de passer au TP4 :

- [ ] L'index `products` existe avec le bon mapping (`GET /products/_mapping`)
- [ ] Au moins 4 produits ont été indexés manuellement (IDs 1 à 4)
- [ ] La mise à jour partielle fonctionne (prix du produit 1 modifié)
- [ ] Le Bulk API a chargé les produits (`docs.count` > 1000 dans `_cat/indices`)
- [ ] `GET /products/_search` avec `match_all` retourne des résultats
- [ ] Les catégories sont variées (vérifier avec l'agrégation `terms`)

---

*Passez au [TP4 — Requêtes & Recherche](../tp4-requetes/README.md) une fois toutes les vérifications validées.*
