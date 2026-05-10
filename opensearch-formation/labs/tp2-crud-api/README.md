# TP2 — CRUD & API

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

Utilisez le script `exercices.sh` pour créer l'index, ou exécutez directement :

```bash
curl -s -X PUT "http://localhost:9200/products" \
  -H 'Content-Type: application/json' \
  -d '{
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
  }' | python3 -m json.tool
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

```bash
curl -s "http://localhost:9200/products/_mapping" | python3 -m json.tool
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

```bash
curl -s -X POST "http://localhost:9200/products/_refresh"
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

```bash
curl -s -X POST "http://localhost:9200/products/_update/1" \
  -H 'Content-Type: application/json' \
  -d '{
    "script": {
      "source": "ctx._source.price = Math.round(ctx._source.price * 0.9 * 100) / 100.0",
      "lang": "painless"
    }
  }' | python3 -m json.tool
```

### 3.5 Supprimer un document

Complétez le TODO dans `exercices.sh` pour supprimer le produit ID 5 (montre connectée — en rupture de stock).

Structure :
```
DELETE /products/_doc/{id}
```

Vérifiez qu'il n'existe plus :
```bash
curl -s "http://localhost:9200/products/_doc/5"
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

```bash
curl -s -X POST "http://localhost:9200/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @../../data/products-bulk.ndjson | python3 -m json.tool | tail -5
```

> **Note** : `--data-binary` est crucial (à la place de `-d`) pour préserver les retours à la ligne dans le fichier NDJSON.

### 4.3 Vérifier la réponse Bulk

La réponse contient le champ `errors` (true/false) et `items` (résultat pour chaque document). En cas d'erreur, filtrez :

```bash
curl -s -X POST "http://localhost:9200/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @../../data/products-bulk.ndjson \
  | python3 -c "
import json, sys
resp = json.load(sys.stdin)
print('Errors:', resp['errors'])
errors = [item for item in resp['items'] if list(item.values())[0].get('status') >= 400]
print('Documents en erreur:', len(errors))
if errors:
    print('Premier erreur:', json.dumps(errors[0], indent=2))
"
```

---

## Exercice 5 — Vérifier le chargement

### 5.1 Compter les documents

```bash
curl -s "http://localhost:9200/_cat/indices/products?v"
```

Vérifiez la colonne `docs.count` : vous devriez avoir 1004 documents (4 manuels + 1000 du bulk).

### 5.2 Recherche de vérification

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match_all": {} },
    "size": 5
  }' | python3 -m json.tool
```

### 5.3 Statistiques de l'index

```bash
curl -s "http://localhost:9200/products/_stats" | python3 -m json.tool | grep -A 3 '"docs"'
```

### 5.4 Récapitulatif du catalogue

Vérifiez rapidement la distribution des catégories :

```bash
curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "categories": {
        "terms": { "field": "category", "size": 20 }
      }
    }
  }' | python3 -m json.tool
```

---

## TP Bonus — Générer 5000 produits aléatoires

### Option 1 : Script Python

```python
#!/usr/bin/env python3
"""Générateur de produits e-commerce pour OpenSearch."""

import json
import random
import uuid
from datetime import datetime, timedelta

CATEGORIES = {
    "Électronique": ["Smartphones", "Ordinateurs portables", "Tablettes", "Audio", "TV & Vidéo"],
    "Vêtements": ["Hommes", "Femmes", "Enfants", "Sport", "Accessoires"],
    "Maison & Jardin": ["Mobilier", "Décoration", "Jardinage", "Cuisine", "Bricolage"],
    "Livres": ["Informatique", "Sciences", "Roman", "Histoire", "Développement personnel"],
    "Sports": ["Fitness", "Cyclisme", "Natation", "Running", "Sports collectifs"],
    "Beauté": ["Soins visage", "Maquillage", "Parfums", "Soins cheveux", "Bien-être"],
}

BRANDS = ["TechBrand", "CompuPro", "SoundMax", "FitTech", "StyleCo", "HomeDesign",
          "SportPro", "BeautyLux", "GardenLife", "KidsFun", "AutoParts", "PetCare"]

COLORS = ["Noir", "Blanc", "Rouge", "Bleu", "Vert", "Gris", "Or", "Argent", "Rose", "N/A"]

SELLERS = ["TechShop", "MegaStore", "FastDeal", "PremiumShop", "QuickBuy",
           "BestPrice", "TopSeller", "DirectShop", "EasyBuy", "ProStore"]

def random_date(start_year=2022, end_year=2024):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    delta = end - start
    random_days = random.randint(0, delta.days)
    return (start + timedelta(days=random_days)).strftime("%Y-%m-%dT%H:%M:%SZ")

def generate_product(product_id):
    category = random.choice(list(CATEGORIES.keys()))
    sub_category = random.choice(CATEGORIES[category])
    brand = random.choice(BRANDS)
    original_price = round(random.uniform(5, 2000), 2)
    discount = random.uniform(0, 0.4)
    price = round(original_price * (1 - discount), 2)
    created = random_date(2022, 2023)

    return {
        "name": f"{sub_category} {brand} Modèle {random.randint(100, 999)}",
        "description": f"Excellent {sub_category.lower()} de la marque {brand}. "
                       f"Qualité supérieure, livraison rapide. Référence {uuid.uuid4().hex[:8].upper()}.",
        "category": category,
        "sub_category": sub_category,
        "brand": brand,
        "price": price,
        "original_price": original_price,
        "currency": "EUR",
        "in_stock": random.random() > 0.15,
        "stock_quantity": random.randint(0, 500),
        "rating": round(random.uniform(1.0, 5.0), 1),
        "reviews_count": random.randint(0, 10000),
        "tags": [sub_category.lower().replace(" ", "-"), brand.lower(), category.lower()],
        "created_at": created,
        "updated_at": random_date(2023, 2024),
        "seller": random.choice(SELLERS),
        "weight_kg": round(random.uniform(0.01, 50.0), 3),
        "color": random.choice(COLORS),
    }

def main():
    output_file = "products-generated-5000.ndjson"
    count = 5000
    start_id = 2000  # Commencer après les 1000 produits du bulk initial

    with open(output_file, "w", encoding="utf-8") as f:
        for i in range(count):
            product_id = start_id + i
            action = json.dumps({"index": {"_index": "products", "_id": str(product_id)}})
            document = json.dumps(generate_product(product_id), ensure_ascii=False)
            f.write(action + "\n")
            f.write(document + "\n")

    print(f"{count} produits générés dans {output_file}")
    print(f"Pour charger : curl -s -X POST 'http://localhost:9200/_bulk' \\")
    print(f"  -H 'Content-Type: application/x-ndjson' \\")
    print(f"  --data-binary @{output_file}")

if __name__ == "__main__":
    main()
```

### Option 2 : Script Bash (simplifié)

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

Cochez chaque point avant de passer au TP3 :

- [ ] L'index `products` existe avec le bon mapping (`GET /products/_mapping`)
- [ ] Au moins 4 produits ont été indexés manuellement (IDs 1 à 4)
- [ ] La mise à jour partielle fonctionne (prix du produit 1 modifié)
- [ ] Le Bulk API a chargé les produits (`docs.count` > 1000 dans `_cat/indices`)
- [ ] `GET /products/_search` avec `match_all` retourne des résultats
- [ ] Les catégories sont variées (vérifier avec l'agrégation `terms`)

---

*Passez au [TP3 — Requêtes & Agrégations](../tp3-requetes-agregations/README.md) une fois toutes les vérifications validées.*
