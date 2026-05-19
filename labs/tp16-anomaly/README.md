# TP16 — Anomaly Detection SpaceX

## Informations générales

| Paramètre  | Valeur                                                               |
|------------|----------------------------------------------------------------------|
| Durée      | 20 minutes                                                           |
| Difficulté | Intermédiaire                                                        |
| Prérequis  | Index `spacex-launches` créé (TP14 ou TP15), OpenSearch Dashboards accessible sur http://localhost:5601 |

## Objectif

Configurer un détecteur d'anomalies OpenSearch sur les données de lancement SpaceX. L'algorithme RCF (Random Cut Forest) va identifier les périodes avec des comportements anormaux dans les numéros de vol.

---

## Si vous n'avez pas assez de données — Injecter des anomalies

Si l'index `spacex-launches` contient moins de 50 documents ou si les données ne couvrent pas assez de temps pour l'analyse, injectez les données de test avec des pics anormaux :

```bash
curl -XPOST http://localhost:9200/spacex-launches/_bulk \
  -H "Content-Type: application/json" \
  --data-binary @bulk-anomalies.ndjson
```

Vérifiez ensuite :

```
GET /spacex-launches/_count
```

---

## Exercice 1 — Créer le détecteur d'anomalies

### 1.1 Ouvrir Anomaly Detection dans Dashboards

1. Ouvrez http://localhost:5601
2. Dans le menu de gauche, cliquez sur l'icône hamburger (☰)
3. Allez dans **OpenSearch Plugins** → **Anomaly Detection**
4. Cliquez sur **Create detector**

### 1.2 Configurer le détecteur

**Étape 1 — Define detector :**
- Name : `SpaceX Launch Anomaly Detector`
- Index : `spacex-launches`
- Timestamp field : `@timestamp` (ou `date_utc` si `@timestamp` n'est pas disponible)

**Étape 2 — Configure model :**
- Feature name : `flight_count`
- Aggregation method : `count()`
- Field : `flight_number`
- Detector interval : `1 month`
- Window delay : `1 month`
- Shingle size : `8`

> Le shingle size définit le nombre de intervalles consécutifs utilisés pour détecter les anomalies. Une valeur de 8 mois donne un contexte suffisant.

**Étape 3 — Set up alerts (optionnel pour l'instant) :**
- Ignorez pour l'instant et cliquez sur **Skip**

**Étape 4 — Review and create :**
- Vérifiez la configuration et cliquez sur **Create detector**

---

## Exercice 2 — Lancer l'analyse historique

### 2.1 Démarrer l'analyse sur toutes les données

Après la création du détecteur :
1. Cliquez sur **Start detector** pour lancer le détecteur en temps réel
2. Cliquez sur **Run historical analysis** pour analyser les données passées
3. Sélectionnez la plage : choisissez les dates couvrant toutes vos données SpaceX
4. Cliquez sur **Run**

> L'analyse peut prendre 1 à 2 minutes selon le volume de données.

---

## Exercice 3 — Explorer les résultats

### 3.1 Anomaly Explorer

1. Dans la page du détecteur, cliquez sur l'onglet **Anomaly results**
2. Explorez l'**Anomaly Explorer** — visualisation temporelle des anomalies détectées
3. Filtrez les résultats significatifs en cherchant les points avec `anomaly_grade > 0.7`

### 3.2 Interpréter les métriques

- `anomaly_grade` : score entre 0 et 1 (0 = normal, 1 = très anormal)
- `confidence` : niveau de confiance de la détection (entre 0 et 1)

### 3.3 Vérifier via API (optionnel)

Vérifiez l'existence de l'index de résultats :

```
GET /.opendistro-anomaly-results*/_count
```

---

## Exercice 4 — Ajouter le widget au dashboard TP12

### 4.1 Ouvrir le dashboard Product Analytics

1. Allez dans **Dashboard** et ouvrez le dashboard "Product Analytics" créé en TP12
2. Cliquez sur **Edit**

### 4.2 Ajouter un panel Anomaly Detection

1. Cliquez sur **Add** → **Add panel**
2. Sélectionnez **Anomaly Detector**
3. Choisissez le détecteur `SpaceX Launch Anomaly Detector`
4. Cliquez sur **Add**
5. Sauvegardez le dashboard

---

## Exercice Bonus — Alerting sur les anomalies

### Créer un monitor d'anomalies

1. Allez dans **OpenSearch Plugins** → **Alerting** → **Monitors**
2. Cliquez sur **Create monitor**
3. Choisissez **Anomaly detector monitor**
4. Sélectionnez le détecteur `SpaceX Launch Anomaly Detector`

**Condition :**
```
anomaly_grade > 0.8 AND confidence > 0.5
```

**Action :**
- Channel type : `Custom webhook` ou `Index` (pour écrire dans `anomaly-alerts`)
- Si Index : index name `anomaly-alerts`

---

## Vérification finale

- [ ] Détecteur `SpaceX Launch Anomaly Detector` créé avec succès
- [ ] Analyse historique lancée et terminée
- [ ] Anomaly Explorer consulté — des anomalies ont été détectées
- [ ] Au moins une anomalie avec `anomaly_grade > 0.7` identifiée
- [ ] Widget Anomaly Detection ajouté au dashboard TP12
- [ ] (Bonus) Monitor d'alerting créé avec condition sur `anomaly_grade`

---

## Ressources

- [Anomaly Detection OpenSearch](https://opensearch.org/docs/latest/observing-your-data/ad/index/)
- [Random Cut Forest](https://opensearch.org/docs/latest/observing-your-data/ad/settings/)
- [Alerting monitors](https://opensearch.org/docs/latest/observing-your-data/alerting/monitors/)

*Suite : [TP17 — Parent-Child (OPTIONNEL)](../tp17-parent-child/README.md)*
