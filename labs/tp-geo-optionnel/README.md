# TP Optionnel — Requêtes géographiques

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 30 minutes                                           |
| Niveau     | Optionnel — pour aller plus loin                     |
| Prérequis  | TP2 terminé (mapping avec geo_point)                 |
| Objectif   | geo_point, geo_distance, geo_bounding_box            |

## Objectif

Implémenter des requêtes géographiques sur le catalogue produits pour trouver les produits disponibles dans un rayon donné (ex. stock local d'un vendeur).

---

## Exercice 1 — Créer un index avec géolocalisation

```
PUT /stores
{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": {
    "properties": {
      "name":     { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
      "city":     { "type": "keyword" },
      "location": { "type": "geo_point" },
      "stock":    { "type": "integer" }
    }
  }
}
```

### Indexer des magasins

> **Note** : Le chargement de fichiers NDJSON se fait via curl, pas depuis le Dev Console.

```bash
curl -s -X POST "http://localhost:9200/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  -d '{"index":{"_index":"stores","_id":"1"}}
{"name":"Store Paris Centre","city":"Paris","location":{"lat":48.8566,"lon":2.3522},"stock":150}
{"index":{"_index":"stores","_id":"2"}}
{"name":"Store Lyon Bellecour","city":"Lyon","location":{"lat":45.7578,"lon":4.8320},"stock":89}
{"index":{"_index":"stores","_id":"3"}}
{"name":"Store Marseille Vieux-Port","city":"Marseille","location":{"lat":43.2965,"lon":5.3698},"stock":210}
{"index":{"_index":"stores","_id":"4"}}
{"name":"Store Bordeaux Quinconces","city":"Bordeaux","location":{"lat":44.8378,"lon":-0.5792},"stock":67}
{"index":{"_index":"stores","_id":"5"}}
{"name":"Store Lille Grand-Place","city":"Lille","location":{"lat":50.6292,"lon":3.0573},"stock":45}
'
```

---

## Exercice 2 — `geo_distance` — Magasins dans un rayon

Trouver tous les magasins dans un rayon de 300 km de Paris :

```
GET /stores/_search
{
  "query": {
    "geo_distance": {
      "distance": "300km",
      "location": { "lat": 48.8566, "lon": 2.3522 }
    }
  },
  "sort": [
    {
      "_geo_distance": {
        "location": { "lat": 48.8566, "lon": 2.3522 },
        "order":  "asc",
        "unit":   "km"
      }
    }
  ]
}
```

---

## Exercice 3 — `geo_bounding_box` — Magasins dans une zone rectangulaire

```
GET /stores/_search
{
  "query": {
    "geo_bounding_box": {
      "location": {
        "top_left":     { "lat": 51.0, "lon": -2.0 },
        "bottom_right": { "lat": 43.0, "lon": 6.0 }
      }
    }
  }
}
```

> Cette bounding box couvre approximativement la France métropolitaine.

---

## Exercice 4 — Agrégation `geo_distance`

Compter les magasins par zone de distance depuis Paris :

```
GET /stores/_search
{
  "size": 0,
  "aggs": {
    "zones_autour_paris": {
      "geo_distance": {
        "field": "location",
        "origin": { "lat": 48.8566, "lon": 2.3522 },
        "unit": "km",
        "ranges": [
          { "key": "Proche (< 100km)",   "to": 100 },
          { "key": "Moyen (100-400km)",  "from": 100, "to": 400 },
          { "key": "Loin (> 400km)",     "from": 400 }
        ]
      },
      "aggs": {
        "stock_total": { "sum": { "field": "stock" } }
      }
    }
  }
}
```

---

## Vérification finale

- [ ] Index `stores` créé avec champ `geo_point`
- [ ] 5 magasins indexés
- [ ] `geo_distance` retourne les magasins dans un rayon de 300km de Paris
- [ ] `geo_bounding_box` retourne les magasins dans la bounding box France
- [ ] Agrégation `geo_distance` compte les magasins par zone
