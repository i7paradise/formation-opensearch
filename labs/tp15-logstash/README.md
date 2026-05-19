# TP15 — Ingestion Logstash SpaceX

## Informations générales

| Paramètre  | Valeur                                                              |
|------------|---------------------------------------------------------------------|
| Durée      | 35 minutes                                                          |
| Difficulté | Intermédiaire                                                       |
| Prérequis  | Docker installé, fichier `infrastructure/docker-compose.logstash.yml` |

## Objectif

Utiliser Logstash pour ingérer les données SpaceX depuis un fichier NDJSON vers OpenSearch. Vous allez configurer un pipeline Input → Filter → Output et comparer le résultat avec celui obtenu via Data Prepper (TP14).

---

## Exercice 1 — Démarrer l'infrastructure Logstash

### 1.1 Lancer les conteneurs

```bash
docker compose -f infrastructure/docker-compose.logstash.yml up -d
```

### 1.2 Attendre qu'OpenSearch soit prêt

```bash
curl -s http://localhost:9200/_cluster/health | jq '.status'
```

Attendez d'obtenir `"green"` ou `"yellow"` avant de continuer.

> Note : Logstash démarre plus lentement qu'OpenSearch. Attendez 30 à 60 secondes.

---

## Exercice 2 — Préparer les données SpaceX

### 2.1 Télécharger les données en format NDJSON

Logstash lit les fichiers ligne par ligne. Il faut convertir le tableau JSON en NDJSON (un objet JSON par ligne) :

```bash
curl -s https://api.spacexdata.com/v4/launches \
  | jq -c '.[]' \
  > infrastructure/logstash/data/launches.ndjson
```

Vérifiez le nombre de lignes :

```bash
wc -l infrastructure/logstash/data/launches.ndjson
```

---

## Exercice 3 — Créer le pipeline Logstash

### 3.1 Créer le fichier de configuration

Créez le fichier `infrastructure/logstash/pipeline/spacex.conf` :

```ruby
input {
  file {
    path => "/data/launches.ndjson"
    codec => "json"
    sincedb_path => "/dev/null"
    start_position => "beginning"
  }
}

filter {
  mutate {
    add_field => {
      "source" => "logstash"
      "ingested_at" => "%{@timestamp}"
    }
    rename => { "date_utc" => "launch_date" }
  }
}

output {
  opensearch {
    hosts => ["http://opensearch-node1:9200"]
    index => "spacex-logstash"
    document_id => "%{[id]}"
  }
  stdout { codec => dots }
}
```

> `sincedb_path => "/dev/null"` force la relecture du fichier à chaque redémarrage.
> `document_id => "%{[id]}"` évite les doublons en utilisant l'ID SpaceX comme `_id`.

---

## Exercice 4 — Démarrer l'ingestion

### 4.1 Redémarrer Logstash pour charger le pipeline

```bash
docker restart logstash
```

### 4.2 Suivre les logs en temps réel

```bash
docker logs logstash -f
```

Vous devriez voir des points (`.`) s'afficher — chaque point représente un batch de documents traités.

> Appuyez sur `Ctrl+C` pour quitter les logs sans arrêter Logstash.

---

## Exercice 5 — Vérifier l'ingestion dans OpenSearch

### 5.1 Compter les documents

```
GET /spacex-logstash/_count
```

### 5.2 Inspecter le mapping généré

```
GET /spacex-logstash/_mapping
```

Notez les différences avec le mapping de `spacex-launches` (TP14) : Logstash génère un mapping dynamique différent de Data Prepper.

### 5.3 Comparer les deux index

```
GET /spacex-launches,spacex-logstash/_count
```

---

## Exercice 6 — Comparer Data Prepper et Logstash

Remplissez ce tableau de comparaison :

| Critère                  | Data Prepper (TP14) | Logstash (TP15) |
|--------------------------|---------------------|-----------------|
| Champ date principal     | `@timestamp`        | `@timestamp` (Logstash natif) + `launch_date` |
| Champ `date_utc`         | Converti            | Renommé en `launch_date` |
| Champ source             | `source: spacex-api` | `source: logstash` |
| Mode d'ingestion         | HTTP push           | Lecture fichier  |
| Document ID              | Auto-généré         | ID SpaceX (`%{[id]}`) |

---

## Exercice Bonus — Taguer les lancements échoués

Modifiez le filter de `spacex.conf` pour ajouter un tag aux lancements échoués et les router vers un index dédié :

```ruby
filter {
  mutate {
    add_field => {
      "source" => "logstash"
      "ingested_at" => "%{@timestamp}"
    }
    rename => { "date_utc" => "launch_date" }
  }
  if [success] == false {
    mutate {
      add_tag => ["failed_launch"]
    }
  }
}

output {
  if "failed_launch" in [tags] {
    opensearch {
      hosts => ["http://opensearch-node1:9200"]
      index => "spacex-failures"
      document_id => "%{[id]}"
    }
  } else {
    opensearch {
      hosts => ["http://opensearch-node1:9200"]
      index => "spacex-logstash"
      document_id => "%{[id]}"
    }
  }
  stdout { codec => dots }
}
```

Redémarrez Logstash et vérifiez l'index `spacex-failures`.

---

## Vérification finale

- [ ] Infrastructure Logstash démarrée (OpenSearch + Logstash)
- [ ] Fichier `launches.ndjson` créé dans `infrastructure/logstash/data/`
- [ ] Pipeline `spacex.conf` créé dans `infrastructure/logstash/pipeline/`
- [ ] Index `spacex-logstash` créé avec des documents
- [ ] Mapping inspecté et comparé avec TP14
- [ ] (Bonus) Index `spacex-failures` créé avec les lancements échoués

---

## Ressources

- [Documentation Logstash](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Plugin OpenSearch pour Logstash](https://github.com/opensearch-project/logstash-output-opensearch)
- [Plugin file input](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-file.html)

*Suite : [TP13 — ISM, Aliases & Snapshots](../tp13-reindex-ism/README.md)*
