# Jour 2 — Guide formateur : Fonctionnalités Avancées & Dashboards

## Timing global

| Heure | Durée | Activité | Type |
|-------|-------|----------|------|
| 09:00 | 15 min | Récap Jour 1 — 6 questions orales | Q/A |
| 09:15 | 60 min | Chapitre 4a : Ingest Pipelines | Cours |
| 10:15 | 15 min | Pause | Pause |
| 10:30 | 30 min | Chapitre 4b : Analyseurs & Tokenizers | Cours |
| 11:00 | 30 min | Chapitre 4c : Tri, Suggestion, Géo & Optimisation | Cours |
| 11:30 | 60 min | TP4 : Fonctionnalités avancées | TP |
| 12:30 | 60 min | Déjeuner | Déjeuner |
| 13:30 | 30 min | Chapitre 5a : Principes Dashboards | Cours |
| 14:00 | 30 min | Chapitre 5b : Agrégations & Visualisations | Cours |
| 14:30 | 30 min | Chapitre 5c : Maps & Dashboard | Cours |
| 15:00 | 15 min | Pause | Pause |
| 15:15 | 75 min | TP5 : Dashboard e-commerce | TP |
| 16:30 | 30 min | Récap Jour 2 + Q&A + preview Jour 3 | Q/A |

---

## Récap Jour 1 (09:00 — 15 min)

**Timing** : 15 min

**Ce que tu dis** :
> "Bonjour tout le monde ! Bien dormi ? Avant de démarrer, on va faire un récap rapide de hier. Je vais vous poser 6 questions — on lève la main pour répondre."

**Questions à poser** :
1. "Quelle est la différence entre un index et un shard ?"
   → Index = logique (comme une table), shard = physique (index Lucene réel)
2. "Quand utilise-t-on `text` vs `keyword` ?"
   → text = recherche full-text analysée, keyword = valeur exacte (filtre, tri, agg)
3. "À quoi sert le Bulk API ?"
   → Indexer des milliers de documents en une seule requête HTTP (beaucoup plus efficace)
4. "Quelle est la différence entre `must` et `filter` dans un bool query ?"
   → must affecte le score + non cacheable. filter = pas de score + cacheable = plus rapide
5. "Qu'est-ce que BM25 utilise pour calculer le score ?"
   → TF (fréquence du terme), IDF (fréquence inverse), longueur du champ
6. "Quelle agrégation donne les valeurs les plus fréquentes ?"
   → `terms` aggregation sur un champ keyword

**Points clés** :
- Repérez qui a besoin d'aide pour finir les TPs d'hier
- Si plus de 3 personnes n'ont pas fini TP2 ou TP3, proposez 15 min supplémentaires

**Alerte** : Si quelqu'un répond "text" pour une agrégation par catégorie → expliquer que les aggs ne fonctionnent que sur keyword

**Transition** :
> "Super ! Aujourd'hui on monte d'un cran. On va voir comment enrichir les données automatiquement, comment rendre la recherche intelligente en français, et comment visualiser tout ça dans des dashboards professionnels."

---

## Chapitre 4a — Ingest Pipelines (09:15 — 60 min)

### Slide : Concept des Pipelines

**Timing** : 10 min

**Ce que tu dis** :
> "Imaginez que vous recevez des données d'un système externe. Les catégories sont en majuscules, les descriptions ont des espaces en trop, et il n'y a pas de timestamp d'indexation. Vous pourriez corriger ça dans votre code client... mais vous devrez le faire dans CHAQUE client. Avec un ingest pipeline, vous centralisez cette logique dans OpenSearch, et tous les clients en bénéficient automatiquement."

**Points clés** :
- Pipeline = séquence de processeurs, exécutée côté serveur à l'indexation
- Différence fondamentale avec les analyseurs : pipeline s'exécute UNE FOIS sur le document entier. Analyseur s'exécute sur un champ text à l'indexation ET à la recherche
- `_simulate` est indispensable : toujours tester avant d'appliquer en production

**Anecdote** :
> "En prod, j'ai vu un pipeline mal configuré avec un processeur `remove` sur un mauvais champ. Résultat : 2 millions de documents sans leur champ `user_id`. La seule solution : reindexer depuis une sauvegarde. _simulate aurait évité ça en 30 secondes."

**Questions fréquentes** :
- Q: "Peut-on appliquer un pipeline en mode batch sur des données déjà indexées ?" → R: "Oui, avec `_update_by_query?pipeline=mon-pipeline`. Attention : ça re-passe par le pipeline et consomme des ressources."
- Q: "Le pipeline ralentit-il l'indexation ?" → R: "Légèrement, mais c'est négligeable pour des pipelines simples. Les processeurs lourds (grok sur chaque doc) peuvent impacter."

**Transition** :
> "Maintenant qu'on sait transformer les données, voyons comment rendre la recherche intelligente avec les analyseurs."

---

### Slide : Processeurs courants

**Timing** : 10 min

**Ce que tu dis** :
> "Il existe une trentaine de processeurs. Les plus utilisés : `lowercase` pour normaliser les catégories, `trim` pour supprimer les espaces, `set` pour ajouter des champs calculés, `grok` pour parser des logs. Regardons comment les combiner."

**Démo live** : Créer le pipeline `pipeline-produits` et le tester avec `_simulate`. Montrez la transformation de `"ELECTRONIQUE"` en `"electronique"` et la suppression des espaces.

**Points clés** :
- `ignore_missing: true` évite les erreurs si le champ n'existe pas
- `{{_ingest.timestamp}}` est une variable magique = moment exact de l'indexation
- Ordre des processeurs = ordre d'exécution (important si un processeur dépend d'un autre)

---

## Chapitre 4b — Analyseurs & Tokenizers (10:30 — 30 min)

### Slide : Chaîne d'analyse

**Timing** : 10 min

**Ce que tu dis** :
> "C'est LE concept le plus important du jour 2. Quand vous indexez 'Vélos électriques d'entrée de gamme', OpenSearch ne stocke pas ce texte tel quel dans l'index inversé. Il le transforme en tokens. Voici comment."

**Points clés** :
- ORDRE : Char Filter → Tokenizer → Token Filters. L'ordre est figé et obligatoire
- `lowercase` doit venir AVANT `asciifolding` : "É" en majuscule doit d'abord être en minuscule "é" pour que asciifolding le transforme en "e"
- Demo en live avec `_analyze` API : montrez les tokens produits étape par étape

**Anecdote** :
> "Le problème le plus fréquent en prod : un développeur cherche 'velo' et ne trouve pas 'Vélo'. Cause : l'analyseur manque d'asciifolding ou n'est pas appliqué à la recherche. L'analyseur doit être symétrique : même transformation à l'indexation ET à la recherche."

**Questions fréquentes** :
- Q: "Peut-on avoir différents analyseurs pour l'indexation et la recherche ?" → R: "Oui, `analyzer` pour l'index, `search_analyzer` pour la recherche. Mais en pratique, 95% du temps vous utilisez le même pour les deux."
- Q: "Où va-t-on trouver la liste de tous les token filters ?" → R: "Documentation officielle opensearch.org/docs/latest/analyzers/"

**Alerte** : "Si quelqu'un applique un analyseur APRÈS avoir indexé des données → il doit réindexer ! Les tokens existants dans l'index ne changent pas rétroactivement."

**Transition** :
> "On vient de créer notre analyseur français. Maintenant on va voir des fonctionnalités plus visuelles : l'autocomplétion, le highlighting, et la recherche géographique."

---

## Chapitre 4c — Tri, Suggestion, Géo & Optimisation (11:00 — 30 min)

### Slide : Completion Suggester

**Timing** : 10 min

**Ce que tu dis** :
> "Qui utilise la barre de recherche d'Amazon ? Quand vous tapez 'ord', vous avez instantanément des suggestions : 'ordinateur', 'ordinateur portable', etc. C'est le completion suggester. Il utilise une structure de données spécialisée — le Finite State Transducer — qui est chargée en mémoire et permet des suggestions en moins d'une milliseconde."

**Points clés** :
- Type `completion` obligatoire dans le mapping
- Les données doivent être indexées dans ce champ (il faut donc réindexer ou update_by_query)
- `fuzziness: 1` tolère une faute de frappe (distance d'édition 1)

**Transition** :
> "Pour la correction orthographique — 'Voulez-vous dire ?' — on utilise le term suggester, qui est différent. Voyons ensuite la géo."

### Slide : Géo & Optimisation

**Timing** : 10 min

**Ce que tu dis** :
> "Notre e-commerce a des magasins physiques. Les clients veulent trouver le magasin le plus proche. Avec geo_distance + geo_point, c'est trivial dans OpenSearch."

**Démo live** : Montrez la requête geo_distance avec le sort par distance. Montrez que la distance calculée apparaît dans le résultat.

**Points clés Optimisation** :
- Le conseil le plus important : "En cas de doute entre `must` et `filter`, mettez dans `filter`"
- `dynamic: strict` = protection contre le mapping explosion (champs inattendus créent des mappings dynamiques)
- Évitez les wildcards en début de pattern : `*term` → scan complet de l'index

---

## TP4 — Fonctionnalités avancées (11:30 — 60 min)

**Ce que tu dis** :
> "Ouvrez labs/tp4-fonctionnalites-avancees/README.md. Vous avez 60 minutes pour les 6 exercices. La solution est dans labs/tp4-fonctionnalites-avancees/solution/solution.sh si vous êtes bloqués."

**Points de surveillance** :
- Ex.1 : _simulate avant d'indexer avec le pipeline
- Ex.2-3 : L'exercice de réindexation est le plus difficile — vérifiez que products-v2 a le bon count
- Ex.4 : Le completion suggester nécessite un champ completion dans le mapping et de réindexer avec le script pour copier name vers name_suggest
- Ex.6 : Vérifier que l'index stores existe : `GET /stores/_count`

**Alerte** : Si quelqu'un dit "mon analyseur ne fonctionne pas" → Demandez : est-ce que l'index a été créé AVANT ou APRÈS l'analyseur ? Si avant, les données ne sont pas analysées avec le bon analyseur.

---

## Chapitre 5a — Principes Dashboards (13:30 — 30 min)

### Slide : Interface

**Timing** : 10 min

**Ce que tu dis** :
> "OpenSearch Dashboards, c'est l'équivalent de Kibana pour Elasticsearch — en fait, c'est un fork de Kibana. C'est l'interface qui permet à des non-développeurs d'explorer et visualiser les données sans écrire de JSON. Voyons l'interface."

**Démo live** : Ouvrez http://localhost:5601. Faites un tour de chaque section. Insistez sur l'ordre : Management → Index Pattern → Discover → Visualize → Dashboard.

**Points clés** :
- Index Pattern = obligatoire avant TOUT
- Le champ date dans l'Index Pattern active les filtres temporels (Time Range picker)
- KQL est sensible à la casse sur les keyword fields

**Question fréquente** :
- Q: "Quelle est la différence avec Kibana ?" → R: "Kibana appartient à Elastic (SSPL). Dashboards est le fork OpenSearch (Apache 2.0). L'interface est similaire mais pas identique. Les saved objects ne sont pas compatibles entre les deux."

---

## Chapitre 5b — Agrégations & Visualisations (14:00 — 30 min)

**Timing** : 30 min

**Ce que tu dis** :
> "Chaque visualisation Dashboards est construite sur une agrégation OpenSearch. Quand vous créez un Pie Chart, Dashboards exécute une terms aggregation en coulisse. La maîtrise des agrégations qu'on a vue hier est directement réutilisable ici."

**Table de correspondance à mémoriser** :
- Bar Chart + Terms = top N valeurs
- Line Chart + Date Histogram = évolution dans le temps
- Pie Chart + Terms = répartition proportionnelle
- Metric + Count/Avg/Sum = KPI
- Data Table + Terms + Metric = rapport détaillé

**Démo live** : Créez un Pie Chart en direct. Montrez : choisir le type de viz, configurer le bucket (Terms sur category), configurer la métrique (Count), voir le résultat.

**Alerte** : "Si quelqu'un essaie de faire une agrégation Terms sur un champ `text` → erreur 'Fielddata is disabled'. Il faut utiliser le sous-champ `.keyword` : `category.keyword`."

---

## Chapitre 5c — Maps & Dashboards (14:30 — 30 min)

**Ce que tu dis** :
> "On peut placer nos données géographiques sur une carte interactive. Le Coordinate Map utilise une geohash aggregation — il divise la carte en cellules hexagonales et compte les documents dans chaque cellule."

**Points clés** :
- Le Coordinate Map nécessite l'index `stores` avec le champ `location` de type `geo_point`
- Les tuiles de carte nécessitent une connexion internet (OpenStreetMap)
- Construction de dashboard : ordre logique = créer toutes les viz d'abord, assembler ensuite

**Ce que tu dis (Dashboard assembly)** :
> "Pour assembler un dashboard, pensez comme un chef de cuisine : préparez tous vos ingrédients d'abord (les visualisations), puis assemblez le plat (le dashboard). Ne créez pas de viz directement depuis le dashboard — vous perdrez la possibilité de les réutiliser ailleurs."

---

## TP5 — Dashboard e-commerce (15:15 — 75 min)

**Ce que tu dis** :
> "C'est le TP le plus visuel de la formation. Ouvrez labs/tp5-dashboards/README.md. Vous allez créer le tableau de bord e-commerce complet."

**Points de surveillance** :
- Index Pattern : vérifiez que le champ date est `created_at`
- KQL dans Discover : rappel que les keyword fields sont case-sensitive
- Coordinate Map : si les tuiles ne chargent pas → problème réseau. Offrez une alternative : screenshot de référence
- Data Table : pour les produits les plus chers, trier par `price` descending

**Alerte** : "Si quelqu'un obtient 0 résultats dans Discover → vérifiez la plage temporelle dans le coin supérieur droit. Par défaut c'est 'Last 15 minutes'. Changez en 'Last 1 year' ou 'Last 12 months'."

---

## Récap Jour 2 (16:30 — 30 min)

**Ce que tu dis** :
> "Journée chargée ! Récapitulons. Ce matin : ingest pipelines pour normaliser les données, analyseur français pour une recherche linguistiquement correcte, autocomplétion et géolocalisation. Cet après-midi : Dashboards pour visualiser tout ça sans écrire une ligne de code."

**Questions récap** :
1. "Quel processeur parse du texte non structuré avec des patterns ?" → grok
2. "Dans la chaîne d'analyse, qu'est-ce qui vient en premier ?" → Char Filter
3. "Quel token filter supprime les accents ?" → asciifolding
4. "Quelle visualisation pour une évolution dans le temps ?" → Line Chart + Date histogram

**Preview Jour 3** :
> "Demain, c'est le jour de la production. On va passer à 3 nœuds, configurer la haute disponibilité, faire de la gestion de cycle de vie des index, et sécuriser le cluster avec TLS et RBAC. C'est le jour le plus technique, et aussi le plus satisfaisant."

**Important** :
> "N'oubliez pas de signer la feuille de présence pour l'après-midi ! Et si vous n'avez pas fini les TPs, vous pouvez continuer ce soir — les solutions sont dans les dossiers `solution/`."

---

*Guide Jour 2 — Formation OpenSearch 3.6*
