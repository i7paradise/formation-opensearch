# TP2 — Créer un index complet avec tous les types de champs

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 30 minutes                                           |
| Difficulté | Débutant                                             |
| Prérequis  | TP1 terminé et validé — cluster OpenSearch en cours d'exécution |
| Objectif   | Créer un mapping explicite couvrant tous les types de champs OpenSearch |

## Objectif

Créer à la main un index `produits_complet` couvrant tous les types de champs OpenSearch. Ce TP ancre immédiatement les connaissances du Chapitre 3a sur les mappings.

## Contexte fil rouge

Avant de charger notre vrai catalogue produits e-commerce (TP3), nous allons créer un index de démonstration qui couvre tous les types de champs. Cela nous permettra de comprendre concrètement la différence entre `text` et `keyword`, l'utilité du type `date`, du `geo_point`, du `nested`, etc.

---

## Exercice 1 — Créer un mapping explicite complet

### 1.1 Créer l'index avec tous les types de champs

```
PUT /produits_complet
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "dynamic": "strict"
  },
  "mappings": {
    "properties": {
      "name": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword" } }
      },
      "description":    { "type": "text" },
      "category":       { "type": "keyword" },
      "price":          { "type": "float" },
      "stock_quantity": { "type": "integer" },
      "in_stock":       { "type": "boolean" },
      "created_at":     { "type": "date" },
      "location": {
        "type": "geo_point"
      },
      "attributes": {
        "type": "nested",
        "properties": {
          "key":   { "type": "keyword" },
          "value": { "type": "keyword" }
        }
      },
      "tags": { "type": "keyword" }
    }
  }
}
```

**Réponse attendue :**
```json
{ "acknowledged": true, "shards_acknowledged": true, "index": "produits_complet" }
```

### 1.2 Vérifier le mapping créé

```
GET /produits_complet/_mapping
```

---

## Exercice 2 — Indexer des documents de test

```
PUT /produits_complet/_doc/1
{
  "name": "Smartphone Pro Max 256Go",
  "description": "Smartphone haut de gamme avec écran AMOLED",
  "category": "Électronique",
  "price": 899.99,
  "stock_quantity": 42,
  "in_stock": true,
  "created_at": "2024-01-15T10:30:00Z",
  "location": { "lat": 48.8566, "lon": 2.3522 },
  "attributes": [
    { "key": "couleur", "value": "Noir" },
    { "key": "stockage", "value": "256Go" }
  ],
  "tags": ["smartphone", "5G", "AMOLED"]
}
```

Indexez un deuxième document :

```
PUT /produits_complet/_doc/2
{
  "name": "Casque Audio Sans Fil",
  "description": "Casque bluetooth réduction de bruit",
  "category": "Audio",
  "price": 199.99,
  "stock_quantity": 89,
  "in_stock": true,
  "created_at": "2024-02-01T09:00:00Z",
  "location": { "lat": 45.7640, "lon": 4.8357 },
  "attributes": [
    { "key": "couleur", "value": "Blanc" },
    { "key": "autonomie", "value": "30h" }
  ],
  "tags": ["casque", "bluetooth", "sans-fil"]
}
```

---

## Exercice 3 — Observer text vs keyword avec `_analyze`

### 3.1 Analyser un champ `text`

```
POST /produits_complet/_analyze
{
  "field": "name",
  "text": "Smartphone Pro Max 256Go"
}
```

> Observez les tokens générés : tout en minuscules, tokenisé par espace.

### 3.2 Analyser le sous-champ `keyword`

```
POST /produits_complet/_analyze
{
  "field": "name.keyword",
  "text": "Smartphone Pro Max 256Go"
}
```

> Un seul token : la valeur exacte, non analysée.

**Question** : Pourquoi une agrégation `terms` sur `name` (text) échoue, mais fonctionne sur `name.keyword` ?

---

## Exercice 4 — Tester `dynamic: strict`

Tentez d'indexer un document avec un champ non mappé :

```
PUT /produits_complet/_doc/99
{
  "name": "Produit test",
  "category": "Test",
  "price": 10.0,
  "stock_quantity": 1,
  "in_stock": true,
  "created_at": "2024-01-01T00:00:00Z",
  "champ_inconnu": "valeur qui ne devrait pas passer"
}
```

**Résultat attendu** : erreur `strict_dynamic_mapping_exception` — le champ `champ_inconnu` n'est pas dans le mapping et `dynamic: strict` rejette l'indexation.

> **Intérêt** : En production, `dynamic: strict` protège contre les fautes de frappe dans les noms de champs et évite les "mapping explosions".

---

## Exercice 5 — Multi-fields et vérification

```
GET /produits_complet/_search
{
  "query": { "match": { "name": "smartphone" } }
}
```

```
GET /produits_complet/_search
{
  "query": { "match_all": {} },
  "sort": [{ "name.keyword": "asc" }]
}
```

---

## TP Bonus — Champ completion (autocomplétion)

Ajoutez un champ `suggest` de type `completion` pour préparer l'autocomplétion (voir TP optionnel dédié) :

```
PUT /produits_avec_suggest
{
  "mappings": {
    "properties": {
      "name":    { "type": "text" },
      "suggest": { "type": "completion" }
    }
  }
}
```

---

## Vérification finale

- [ ] L'index `produits_complet` existe avec le mapping explicite
- [ ] Au moins 2 documents indexés avec succès
- [ ] `_analyze` montre la différence text vs keyword
- [ ] `dynamic: strict` rejette un champ inconnu
- [ ] La recherche full-text sur `name` fonctionne
- [ ] Le tri sur `name.keyword` fonctionne

*Passez au [TP3 — CRUD, Bulk API & bonnes pratiques](../tp3-crud-api/README.md)*
