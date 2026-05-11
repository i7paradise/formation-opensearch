# Jour 3 — Guide formateur : Agrégations, Dashboards & Cycle de vie

## Timing global

| Heure | Durée | Activité | Type |
|-------|-------|----------|------|
| 09:00 | 60 min | Chapitre 5 : Agrégations complètes | Cours |
| 10:00 | 15 min | Pause | Pause |
| 10:15 | 75 min | TP9 : Agrégations avancées (nouveau) | TP |
| 11:30 | 45 min | Chapitre 5b : Scoring BM25, _explain, search_after, optimisation | Cours |
| 12:15 | 15 min | Démo live Agrégations | Démo live |
| 12:30 | 60 min | Déjeuner | Déjeuner |
| 13:30 | 45 min | Chapitre 9 : OpenSearch Dashboards | Cours |
| 14:15 | 45 min | TP10 : Dashboard e-commerce | TP |
| 15:00 | 15 min | Pause | Pause |
| 15:15 | 45 min | Chapitre 10 : Reindex & Cycle de vie | Cours |
| 16:00 | 30 min | TP11 : Reindex + ISM | TP |
| 16:30 | 30 min | Récap global 3 jours + QCM + Satisfaction + Q&A | Q/A + QCM |

---

## Chapitre 5 — Agrégations complètes (09:00 — 60 min)

**Timing** : 60 min — chapitre dense et fondamental pour le TP9 et le TP10

**Ce que tu dis** :
> "Jusqu'ici, on a cherché des documents. Maintenant on va analyser des données. Les agrégations sont le 'GROUP BY + fonctions d'agrégation' d'OpenSearch — mais en beaucoup plus puissant, parce qu'on peut imbriquer les agrégations."

**Fil rouge** : "Ces résultats que vous calculez ici sont exactement ce que vous allez visualiser dans Dashboards cet après-midi."

### Agrégations métriques (15 min)

**Points clés** :
- `stats` : min, max, avg, sum, count en une seule passe
- `extended_stats` : ajoute variance, écart-type, bornes de déviation
- `percentiles` : médiane (P50), P95, P99 — utiles pour les SLAs
- `cardinality` : HyperLogLog, approximatif mais rapide — bon pour "combien de catégories distinctes ?"

### Agrégations bucket (20 min)

**Points clés** :
- `terms` : un bucket par valeur unique. Sur `keyword` uniquement. `size: 10` par défaut.
- `range` : plages personnalisées. Pas d'overlap possible.
- `histogram` : intervalles réguliers. `interval: 100` pour des tranches de 100€.
- `date_histogram` : même chose mais sur les dates. `calendar_interval: month`.
- `filters` : plusieurs filtres nommés → "en stock vs rupture"

### Agrégations imbriquées (15 min)

**Points clés** :
- On peut imbriquer n'importe quelle agrégation dans un bucket
- `terms` sur `category` → `avg` sur `price` → prix moyen par catégorie
- `top_hits` : retourne les documents réels dans un bucket — très utile
- Pas de limite d'imbrication (mais performance dégradée au-delà de 3 niveaux)

### Agrégations pipeline (10 min)

**Points clés** :
- S'appliquent sur les résultats d'autres agrégations (pas sur les documents)
- `max_bucket` : quelle catégorie a le prix moyen le plus élevé ?
- `avg_bucket`, `sum_bucket`, `min_bucket`
- `derivative` : taux de variation entre buckets

**Questions fréquentes** :
- Q: "Les agrégations ralentissent les requêtes ?" → R: "Oui, surtout sur les gros datasets. `size: 0` évite de retourner des hits. Les champs `keyword` sont optimisés pour les aggs."
- Q: "Peut-on combiner une query et des aggs ?" → R: "Oui — la query filtre les documents sur lesquels les aggs s'appliquent. Pattern très courant : query filtre + agg pour les stats des résultats filtrés."

**Transition** :
> "TP9 — 75 minutes pour implémenter toutes ces agrégations sur votre catalogue produits."

---

## Pause (10:00 — 15 min)

---

## TP9 — Agrégations avancées (10:15 — 75 min)

**Ce que tu fais** :
- Ce TP est le plus long (75 min). Bien surveiller le rythme.
- À 11h00 : vérifier que tout le monde est au moins à l'Exercice 3
- Pointer `top_hits` : "C'est exactement ce qu'un front-end e-commerce utilise pour afficher les produits phares par catégorie"
- À 11h25 : "Terminez ce que vous pouvez, les exercices 4 et 5 sont dans la solution"

---

## Chapitre 5b — Scoring BM25 & optimisation (11:30 — 45 min)

**Timing** : 45 min

**Ce que tu dis** :
> "On a utilisé `_explain` en TP4. Maintenant on comprend vraiment ce qu'il y a dedans."

**Points clés — BM25 détaillé** :
- TF (Term Frequency) : plus le terme apparaît dans le doc → score plus élevé
- IDF (Inverse Document Frequency) : terme rare dans l'index → plus discriminant → score plus élevé
- Field Length Norm : terme dans un champ court → plus pertinent que dans un champ long
- Formule : `score = IDF × (TF × (k1+1)) / (TF + k1 × (1 - b + b × fieldLen/avgFieldLen))`
- `k1 = 1.2`, `b = 0.75` par défaut — ajustables avec `similarity`

**Points clés — Pagination profonde** :
- `from + size` : ok jusqu'à 10 000 résultats (paramètre `max_result_window`)
- Au-delà : `search_after` — curseur basé sur la valeur du dernier document
- `search_after` nécessite un tri stable (inclure `_id` comme tri secondaire)
- Scroll API : déprécié pour la pagination, utiliser `search_after`

**Points clés — Optimisation** :
- `filter` vs `must` : filter ne calcule pas de score → 2-5x plus rapide pour les critères binaires
- `_source` filtering : `"_source": ["name", "price"]` évite de transférer les gros champs
- Request caching : les aggs sur des requêtes `size: 0` avec des données non modifiées sont mises en cache
- Éviter les wildcards au début, les `script` queries sur de gros volumes

**Questions fréquentes** :
- Q: "Comment améliorer la pertinence si BM25 ne convient pas ?" → R: "Boosting de champs (`name^2`), `function_score` pour intégrer des signaux métier (note, popularité), ou LTR (Learning To Rank) pour les très gros volumes."

---

## Démo live — Agrégations (12:15 — 15 min)

**Demo** : Requête live combinant query et agrégations pipeline sur le catalogue produits.

```bash
# Catégorie la plus chère parmi les produits en stock
curl -s -X GET "http://localhost:9200/products/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "query": { "term": { "in_stock": true } },
    "aggs": {
      "cats": {
        "terms": { "field": "category", "size": 20 },
        "aggs": { "avg_price": { "avg": { "field": "price" } } }
      },
      "top_cat": { "max_bucket": { "buckets_path": "cats>avg_price" } }
    }
  }' | python3 -m json.tool
```

> "Ce résultat, vous allez le voir dans un bar chart dans Dashboards dans 2 heures."

---

## Déjeuner (12:30 — 60 min)

---

## Chapitre 9 — OpenSearch Dashboards (13:30 — 45 min)

**Timing** : 45 min

**Ce que tu dis** :
> "Dashboards, c'est l'interface graphique d'OpenSearch. C'est ce que vos clients ou vos équipes métier vont utiliser pour analyser les données. On a calculé nos agrégations ce matin — maintenant on les visualise."

**Points clés** :
- Index Patterns (Data Views) : lier un nom logique aux index physiques. Obligatoire avant toute visualisation.
- Discover : explorer les données, appliquer des filtres KQL, sauvegarder des recherches
- KQL (Kibana Query Language) : syntaxe simplifiée. `category: "Électronique" AND price > 500`
- Visualize : Metric, Pie, Bar, Line, Data Table. Chaque visualisation = une agrégation.
- Dashboard : assembler des visualisations. Filtres globaux appliqués à tout le dashboard.
- Maps : mention rapide — pour les champs `geo_point`. TP optionnel dédié.

**Questions fréquentes** :
- Q: "Dashboards c'est comme Kibana ?" → R: "Oui, c'est un fork de Kibana — la même interface, complètement open source."
- Q: "On peut créer des alertes ?" → R: "Oui, avec OpenSearch Alerting — un plugin intégré. Hors scope de ce TP."

---

## TP10 — Dashboard e-commerce (14:15 — 45 min)

**Ce que tu fais** :
- S'assurer que Dashboards est accessible sur http://localhost:5601
- Aider à la création de l'index pattern (étape souvent source de confusion)
- À 14h50 : "Même si vous n'avez pas toutes les visualisations, assemblez le dashboard avec ce que vous avez"

---

## Pause (15:00 — 15 min)

---

## Chapitre 10 — Reindex & Cycle de vie des index (15:15 — 45 min)

**Timing** : 45 min

**Ce que tu dis** :
> "On arrive au bout de la formation. Deux sujets indispensables pour maintenir un cluster en production sur le long terme : changer de mapping sans interruption de service, et automatiser la rotation des vieux index."

### Reindex API (20 min)

**Points clés** :
- Reindex = copier les documents d'un index à un autre
- Zero-downtime via aliases : `products-current` → `products-v1` → basculement atomique vers `products-v2`
- Le basculement d'alias est atomique : pas de window d'indisponibilité
- Reindex avec transformation : `"script": { "source": "ctx._source.champ = ..." }` avec Painless
- `wait_for_completion=false` pour les gros reindex + suivi avec `_tasks`

### Index Templates (5 min)

**Points clés** :
- Appliquer automatiquement un mapping et des settings à tout nouvel index correspondant à un pattern
- Composants : `_component_template` (réutilisables) + `_index_template` (assemblage)

### Aliases avancés (5 min)

**Points clés** :
- Aliases filtrés : l'alias voit seulement les documents correspondant à un filtre
- Alias write index (`is_write_index: true`) : un seul index reçoit les écritures

### ISM — Index State Management (15 min)

**Points clés** :
- Automatiser hot/warm/cold/delete basé sur l'âge ou la taille
- `hot` : données récentes, SSD, écritures actives
- `warm` : replicas=0, force_merge → réduire la consommation
- `delete` : suppression automatique après la période de rétention
- Snapshots : incrémentiels (seuls les segments modifiés), S3/GCS/Azure en prod

**Anecdote** :
> "Sans ISM, j'ai vu des clusters avec 3 ans de logs accumulés occupant 10 TB alors que la rétention contractuelle était de 90 jours. Une politique ISM simple aurait économisé des milliers d'euros de stockage."

**Questions fréquentes** :
- Q: "Snapshots vs replicas ?" → R: "Les replicas protègent contre la perte d'un nœud. Seul un snapshot protège contre la suppression accidentelle d'un index. Les deux sont nécessaires."

---

## TP11 — Reindex + ISM (16:00 — 30 min)

**Ce que tu fais** :
- TP court et ciblé. S'assurer que tout le monde voit le basculement d'alias fonctionner.
- Pointer : "L'application continuerait de fonctionner pendant ce basculement — c'est la magie des aliases."

---

## Récap global 3 jours + QCM + Q&A final (16:30 — 30 min)

**Ce que tu dis** :
> "Trois jours. Voilà ce qu'on a construit ensemble : un moteur de recherche e-commerce complet, sécurisé, distribué sur 3 nœuds, avec des agrégations avancées, des dashboards et une politique de cycle de vie automatisée. C'est exactement ce qu'on retrouve en production chez les grandes plateformes e-commerce."

**Fil rouge e-commerce — résumé visuel** :
1. Index `products` avec mapping explicite (TP2)
2. 1000+ produits chargés via Bulk API (TP3)
3. Recherche full-text + filtres (TP4)
4. Accès sécurisé RBAC + FLS (TP5)
5. Enrichissement via pipeline, analyseur français (TP6)
6. Cluster 3 nœuds haute disponibilité (TP7)
7. Routing optimisé (TP8)
8. Agrégations analytiques (TP9)
9. Dashboard de pilotage (TP10)
10. Migration zero-downtime + rotation automatique (TP11)

**QCM** :
- Envoyer le lien Digiforma (20 questions, 20 minutes)
- Distribuer le questionnaire de satisfaction pendant que les participants répondent au QCM

**Clôture** :
> "Merci pour votre engagement tout au long de ces 3 jours. Les labs restent disponibles, les slides aussi. Si vous avez des questions en production, n'hésitez pas à consulter la documentation OpenSearch 3.6. Bonne continuation !"
