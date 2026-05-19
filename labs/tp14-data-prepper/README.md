# TP14 — Ingestion SpaceX avec Data Prepper

## Informations générales

| Paramètre  | Valeur                                                   |
|------------|----------------------------------------------------------|
| Durée      | 25 minutes                                               |
| Difficulté | Intermédiaire                                            |
| Prérequis  | Docker installé, OpenSearch démarré (infrastructure/docker-compose.yml) |

## Objectif

Utiliser Data Prepper pour ingérer les données de lancement SpaceX depuis l'API publique vers un index OpenSearch. Vous allez créer un pipeline YAML qui transforme les données à la volée (date, enrichissement de champs).

---

## Exercice 1 — Créer le pipeline Data Prepper

### 1.1 Créer le fichier pipeline

Créez le fichier `pipelines/spacex-pipeline.yaml` avec le contenu suivant :

```yaml
spacex-pipeline:
  source:
    http:
      port: 2021
  buffer:
    bounded_blocking:
      buffer_size: 1024
      batch_size: 256
  processor:
    - date:
        from_time_received: false
        destination: "@timestamp"
        match:
          - key: "date_utc"
            patterns: ["yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ssXXX", "ISO8601"]
    - mutate:
        entries:
          - key: source
            value: "spacex-api"
            add_to_existing_only: false
          - key: ingested_by
            value: "data-prepper"
            add_to_existing_only: false
  sink:
    - opensearch:
        hosts: ["https://opensearch-node1:9200"]
        index: "spacex-launches"
        username: "admin"
        password: "Admin@1234!"
        insecure: true
        bulk_size: 100
```

> Le processor `date` convertit `date_utc` en `@timestamp`. Le processor `mutate` ajoute les champs `source` et `ingested_by`.

---

## Exercice 2 — Démarrer Data Prepper

### 2.1 Lancer le conteneur

```bash
docker compose -f docker-compose.data-prepper.yml up -d
```

### 2.2 Vérifier que Data Prepper est sain

```bash
curl http://localhost:4900/health
```

Réponse attendue :
```json
{"status":"ok"}
```

> Attendez 10 à 15 secondes après le démarrage si le health check échoue.

---

## Exercice 3 — Télécharger et ingérer les données SpaceX

### 3.1 Télécharger les données depuis l'API SpaceX

```bash
curl -s https://api.spacexdata.com/v4/launches \
  | jq '[.[] | {name, date_utc, success, flight_number, rocket, launchpad, details}]' \
  > /tmp/spacex.json
```

Vérifiez que le fichier contient des données :

```bash
jq 'length' /tmp/spacex.json
```

### 3.2 Pousser les données vers Data Prepper

```bash
curl -XPOST http://localhost:2021/log/ingest \
  -H "Content-Type: application/json" \
  -d @/tmp/spacex.json
```

Réponse attendue : `{"log":"success"}`

---

## Exercice 4 — Vérifier l'ingestion dans OpenSearch

### 4.1 Compter les documents

```
GET /spacex-launches/_count
```

### 4.2 Inspecter un document

```
GET /spacex-launches/_search?size=1
```

### 4.3 Vérifier les champs ajoutés par le pipeline

Vérifiez que chaque document contient :
- `@timestamp` : date calculée depuis `date_utc`
- `source` : `"spacex-api"`
- `ingested_by` : `"data-prepper"`

```
GET /spacex-launches/_search
{
  "size": 1,
  "_source": ["name", "date_utc", "@timestamp", "source", "ingested_by", "flight_number"]
}
```

---

## Exercice Bonus — Filtrer les lancements echoues

Ajoutez un processor `drop_events` dans le pipeline pour ne garder que les lancements réussis :

```yaml
    - drop_events:
        drop_when: '/success == false'
```

Placez ce processor **avant** le processor `date`. Redémarrez Data Prepper et réingérez les données. Vérifiez que le compte de documents est inférieur au total.

---

## Vérification finale

- [ ] Fichier `pipelines/spacex-pipeline.yaml` créé avec source HTTP, processors date et mutate, sink OpenSearch
- [ ] Data Prepper démarré et sain (`/health` retourne `ok`)
- [ ] Données SpaceX téléchargées (100+ documents)
- [ ] Ingestion réussie vers `spacex-launches`
- [ ] Champ `@timestamp` présent et correctement formaté
- [ ] Champs `source` et `ingested_by` présents
- [ ] (Bonus) Processor `drop_events` ajouté — seuls les lancements réussis sont indexés

---

## Ressources

- [Data Prepper Documentation](https://opensearch.org/docs/latest/data-prepper/)
- [API SpaceX](https://github.com/r-spacex/SpaceX-API)
- [Processors Data Prepper](https://opensearch.org/docs/latest/data-prepper/pipelines/configuration/processors/)

*Suite : [TP15 — Ingestion Logstash SpaceX](../tp15-logstash/README.md)*
