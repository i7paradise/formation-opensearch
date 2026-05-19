# TP17 — Parent-Child (join field) SpaceX

> **OPTIONNEL** — Ce TP est OPTIONNEL. Les relations parent-child via `join` field sont RAM-intensives et complexes à maintenir. Pour la quasi-totalité des cas d'usage, **préférer la dénormalisation** (dupliquer les données parent dans chaque document enfant) ou les **nested documents**. Abordez ce TP uniquement si le temps le permet.

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 30 minutes                                           |
| Difficulté | Avancé                                               |
| Prérequis  | OpenSearch accessible sur http://localhost:9200      |

## Objectif

Comprendre le fonctionnement du `join` field OpenSearch pour modéliser des relations parent-child. Vous allez modéliser la relation entre des fusées (parents) et leurs lancements (enfants).

---

## Exercice 1 — Créer l'index avec mapping join

### 1.1 Créer l'index spacex-join

```
PUT /spacex-join
{
  "mappings": {
    "properties": {
      "join_field": {
        "type": "join",
        "relations": {
          "rocket": "launch"
        }
      },
      "name": { "type": "keyword" },
      "country": { "type": "keyword" },
      "date_utc": { "type": "date" },
      "success": { "type": "boolean" },
      "flight_number": { "type": "integer" }
    }
  }
}
```

### 1.2 Vérifier le mapping

```
GET /spacex-join/_mapping
```

---

## Exercice 2 — Indexer les documents parents (fusées)

### 2.1 Indexer Falcon 9

```
PUT /spacex-join/_doc/rocket-falcon9
{
  "name": "Falcon 9",
  "country": "US",
  "join_field": {
    "name": "rocket"
  }
}
```

### 2.2 Indexer Falcon Heavy

```
PUT /spacex-join/_doc/rocket-falconheavy
{
  "name": "Falcon Heavy",
  "country": "US",
  "join_field": {
    "name": "rocket"
  }
}
```

> Les documents parents n'ont **pas** besoin de paramètre `routing`.

---

## Exercice 3 — Indexer les documents enfants (lancements)

> IMPORTANT : Le routing est **obligatoire** pour les documents enfants. Il doit être égal à l'ID du parent.

### 3.1 Indexer des lancements pour Falcon 9

```
PUT /spacex-join/_doc/launch-1?routing=rocket-falcon9
{
  "name": "CRS-1",
  "date_utc": "2012-10-08T00:35:00.000Z",
  "success": true,
  "flight_number": 9,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falcon9"
  }
}
```

```
PUT /spacex-join/_doc/launch-2?routing=rocket-falcon9
{
  "name": "CRS-2",
  "date_utc": "2013-03-01T15:10:00.000Z",
  "success": true,
  "flight_number": 10,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falcon9"
  }
}
```

```
PUT /spacex-join/_doc/launch-3?routing=rocket-falcon9
{
  "name": "GPS III SV03",
  "date_utc": "2020-06-30T20:10:00.000Z",
  "success": true,
  "flight_number": 90,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falcon9"
  }
}
```

### 3.2 Indexer des lancements pour Falcon Heavy

```
PUT /spacex-join/_doc/launch-4?routing=rocket-falconheavy
{
  "name": "Arabsat-6A",
  "date_utc": "2019-04-11T22:35:00.000Z",
  "success": true,
  "flight_number": 72,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falconheavy"
  }
}
```

```
PUT /spacex-join/_doc/launch-5?routing=rocket-falconheavy
{
  "name": "STP-2",
  "date_utc": "2019-06-25T06:30:00.000Z",
  "success": true,
  "flight_number": 74,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falconheavy"
  }
}
```

```
PUT /spacex-join/_doc/launch-6?routing=rocket-falconheavy
{
  "name": "USSF-44",
  "date_utc": "2022-11-01T13:41:00.000Z",
  "success": true,
  "flight_number": 168,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falconheavy"
  }
}
```

---

## Exercice 4 — Requête has_child

Trouver les fusées qui ont au moins 3 lancements réussis :

```
GET /spacex-join/_search
{
  "query": {
    "has_child": {
      "type": "launch",
      "min_children": 3,
      "query": {
        "term": { "success": true }
      }
    }
  }
}
```

---

## Exercice 5 — Requête has_parent

Trouver tous les lancements de fusées américaines :

```
GET /spacex-join/_search
{
  "query": {
    "has_parent": {
      "parent_type": "rocket",
      "query": {
        "term": { "country": "US" }
      }
    }
  }
}
```

---

## Exercice 6 — Tester l'erreur de routing manquant

Essayez d'indexer un enfant **sans** le paramètre `routing` :

```
PUT /spacex-join/_doc/launch-bad
{
  "name": "Launch sans routing",
  "date_utc": "2023-01-01T00:00:00.000Z",
  "success": true,
  "flight_number": 200,
  "join_field": {
    "name": "launch",
    "parent": "rocket-falcon9"
  }
}
```

Observez l'erreur. OpenSearch refuse l'indexation sans routing car il ne peut pas garantir que le parent et l'enfant sont sur le même shard.

---

## Pourquoi eviter les join fields en production ?

1. **Performance** : `has_child` et `has_parent` sont des requêtes coûteuses (jointure au moment de la requête)
2. **RAM** : Les structures de données join sont chargées en mémoire sur chaque shard
3. **Complexité** : Le routing obligatoire complexifie les indexations en masse
4. **Alternative** : La dénormalisation (dupliquer les champs de la fusée dans chaque document launch) est beaucoup plus performante

### Approche recommandée (dénormalisée)

```json
{
  "launch_name": "CRS-1",
  "rocket_name": "Falcon 9",
  "rocket_country": "US",
  "date_utc": "2012-10-08T00:35:00.000Z",
  "success": true,
  "flight_number": 9
}
```

---

## Vérification finale

- [ ] Index `spacex-join` créé avec `join` field (relation `rocket` → `launch`)
- [ ] 2 parents (Falcon 9, Falcon Heavy) indexés
- [ ] 6 enfants indexés avec routing correct
- [ ] Requête `has_child` retourne les fusées avec 3+ lancements réussis
- [ ] Requête `has_parent` retourne tous les lancements US
- [ ] Erreur de routing manquant observée et comprise

---

## Ressources

- [Join field OpenSearch](https://opensearch.org/docs/latest/field-types/supported-field-types/join/)
- [has_child query](https://opensearch.org/docs/latest/query-dsl/joining/has-child/)
- [has_parent query](https://opensearch.org/docs/latest/query-dsl/joining/has-parent/)
