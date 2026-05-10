# Jour 3 — Guide formateur : Cluster, Administration & Sécurité

## Timing global

| Heure | Durée | Activité | Type |
|-------|-------|----------|------|
| 09:00 | 15 min | Récap Jour 2 — 6 questions orales | Q/A |
| 09:15 | 60 min | Chapitre 6 : Configuration du Cluster | Cours |
| 10:15 | 15 min | Pause | Pause |
| 10:30 | 60 min | Chapitre 7 : Administration du Cluster | Cours |
| 11:30 | 60 min | TP6 : Cluster multi-nœuds | TP |
| 12:30 | 60 min | Déjeuner | Déjeuner |
| 13:30 | 60 min | Chapitre 8 : Sécurité dans OpenSearch | Cours |
| 14:30 | 45 min | TP7 : Sécurisation du cluster | TP |
| 15:15 | 15 min | Pause | Pause |
| 15:30 | 30 min | Récap global 3 jours + fil rouge | Cours |
| 16:00 | 30 min | QCM + Questionnaire satisfaction | QCM |
| 16:30 | 30 min | Q&A final, clôture | Q/A |

---

## Récap Jour 2 (09:00 — 15 min)

**Timing** : 15 min

**Ce que tu dis** :
> "Dernière journée ! Avant de commencer, récap rapide de hier."

**Questions** :
1. "Quelle est la différence entre un ingest pipeline et un analyseur ?"
   → Pipeline : transformation du document entier à l'indexation, une seule fois. Analyseur : sur un champ text, à l'indexation ET à la recherche.
2. "Quel est l'ordre de la chaîne d'analyse ?"
   → Char Filter → Tokenizer → Token Filters
3. "À quoi sert l'asciifolding ?"
   → Convertit les accents en ASCII : é→e, ç→c. Permet de trouver "vélo" en cherchant "velo".
4. "Comment tester un pipeline sans indexer de documents ?"
   → API `_simulate`
5. "Quel type de champ pour le completion suggester ?"
   → `"type": "completion"`
6. "Quelle visualisation Dashboards pour des données géographiques ?"
   → Coordinate Map (avec geohash aggregation)

**Alerte** : Si des participants n'ont pas terminé TP5, proposez-leur de le finir en autonomie pendant TP6.

**Transition** :
> "Aujourd'hui on passe en mode production. Plus de single-node — on va déployer 3 nœuds avec haute disponibilité, configurer des backups automatiques, et sécuriser tout ça avec TLS et RBAC."

---

## Chapitre 6 — Configuration du Cluster (09:15 — 60 min)

### Slide : Types de nœuds

**Timing** : 10 min

**Ce que tu dis** :
> "En single-node, notre nœud fait tout : master, data, ingest, coordinating. En production, on sépare ces rôles. Imaginez une cuisine de restaurant : le chef (master) coordonne, les cuisiniers (data) travaillent les données, les plongeurs (coordinating) font le service."

**Points clés** :
- Le nœud master NE stocke PAS de données — il gère l'état du cluster
- En dessous de 5 nœuds : multi-rôle est acceptable
- Au-delà de 5 nœuds : dédiez 3 nœuds comme master-only

**Anecdote** :
> "J'ai vu un cluster où le nœud master exécutait aussi des grosses requêtes. Quand une query lourde saturait le CPU, le cluster devenait instable car le master ne répondait plus à temps. Séparation des rôles = stabilité."

---

### Slide : Discovery & Quorum

**Timing** : 10 min

**Ce que tu dis** :
> "Le split-brain, c'est le cauchemar de tout administrateur de cluster distribué. Imaginez : le réseau se partitionne. Nœud1 pense que Nœud2 est mort et se proclame master. Nœud2 pense que Nœud1 est mort et fait de même. Résultat : deux clusters qui divergent. Comment l'éviter ? Le quorum."

**Explication quorum** :
> "Le quorum, c'est le nombre minimum de nœuds master-eligible devant être d'accord pour élire un master. Formule : N/2 + 1. Avec 3 nœuds : 3/2 + 1 = 2. Si le réseau se coupe en 1 vs 2, seul le groupe de 2 a le quorum et peut élire un master. Le nœud isolé reste passif."

**Question fréquente** :
- Q: "Peut-on avoir 2 nœuds master-eligible ?" → R: "Techniquement oui, mais JAMAIS en production. Avec 2 nœuds, le quorum = 2. Si les 2 se voient, parfait. Si le réseau se coupe — impossible d'atteindre le quorum → cluster indisponible. Avec 3 nœuds, on peut perdre 1 et rester opérationnel."

**Alerte importante** :
> "`cluster.initial_master_nodes` ne sert QU'AU PREMIER DÉMARRAGE du cluster. Après avoir formé le cluster, RETIREZ cette ligne de la configuration. Si vous la laissez, vous risquez des comportements inattendus lors des redémarrages."

---

### Slide : Shards — Sizing

**Timing** : 8 min

**Ce que tu dis** :
> "Question classique : combien de shards pour mon index ? La règle empirique : 10 à 50 GB par shard. Un shard trop petit crée du overhead (chaque shard consomme de la mémoire pour ses métadonnées). Un shard trop gros rend la réallocation longue."

**Calcul en live** :
> "Exemple concret : vous avez un index de 300 GB. 300 / 30 = 10 shards primaires. Avec 1 replica, vous avez 20 shards au total répartis sur 3 nœuds — environ 6-7 shards par nœud."

**CRITIQUE** :
> "Le nombre de primary shards est IMMUABLE après création. Réfléchissez avant ! Combien de données dans 6 mois ? Dans 2 ans ? C'est la décision la plus importante à la création d'un index."

---

### Slide : Aliases & Index Templates

**Timing** : 12 min

**Ce que tu dis** :
> "Les aliases sont mon outil préféré en production. Ils permettent de reindexer sans aucune interruption de service. La technique : créer `products-v2`, réindexer dedans, puis basculer l'alias atomiquement. L'opération `_aliases` avec plusieurs actions est exécutée de façon atomique — les clients voient soit v1, soit v2, jamais les deux ni aucun."

**Démo live** :
```
1. GET /_cat/aliases
2. PUT /products-v1 (index existant)
3. POST /_aliases (add alias "products" → products-v1)
4. GET /products/_search (fonctionne via l'alias)
5. PUT /products-v2 (nouveau mapping)
6. POST /_reindex
7. POST /_aliases (remove v1, add v2 — atomique)
8. GET /products/_search (maintenant sur v2, transparent)
```

**Index Templates** :
> "Les templates automatisent la création d'index. Créez un template `products-template` pour `products-*`. Désormais, chaque nouvel index `products-2026-05`, `products-v3`, etc. hérite automatiquement du mapping et des settings."

---

## Chapitre 7 — Administration du Cluster (10:30 — 60 min)

### Slide : Snapshots

**Timing** : 20 min

**Ce que tu dis** :
> "Première règle d'administration : les replicas NE SONT PAS des backups. Si vous supprimez un index, les replicas disparaissent aussi. Les snapshots, eux, sont des copies immuables stockées hors du cluster."

**Points clés** :
- Snapshots = incrémentiels (seuls les segments modifiés sont copiés)
- Repository doit être accessible par TOUS les nœuds (NFS, S3, Azure Blob, GCS)
- En production : snapshot quotidien vers S3, rétention 30 jours minimum
- TOUJOURS tester la restauration en pré-prod !

**Anecdote** :
> "Un client avait des backups depuis 6 mois. Un jour, crash disque. On lance la restauration... erreur. Le repository était monté uniquement sur le nœud master. Les autres nœuds n'avaient pas accès. 6 mois de backups inutilisables. Testez toujours."

---

### Slide : ISM (Index State Management)

**Timing** : 20 min

**Ce que tu dis** :
> "ISM, c'est le gestionnaire de cycle de vie des index. Indispensable pour les logs : sans ISM, vos index de logs grossissent indéfiniment jusqu'à remplir le disque. Avec ISM, vous définissez : après 30 jours, supprime l'index. Simple et automatique."

**Explication des états** :
> "Le concept d'état : un index est toujours dans UN état à la fois. L'état définit les actions à exécuter et les conditions de transition vers l'état suivant. Pensez à une machine à états : hot → warm → cold → delete."

**Question fréquente** :
- Q: "La différence entre rollover et delete ?" → R: "Rollover crée un NOUVEL index quand le courant atteint une limite (taille, âge, nombre de docs). Delete supprime l'index courant. En général : rollover pour les logs actifs (garder des petits index), delete pour l'archivage final."

---

### Slide : Monitoring

**Timing** : 20 min

**Ce que tu dis** :
> "Un administrateur OpenSearch surveille 4 métriques clés : heap JVM, CPU, disque, et latence. Si la heap dépasse 75%, le GC devient très agressif et peut causer des pauses. Au-delà de 85%, risque d'OOM Error."

**Commandes de diagnostic** :
```bash
GET /_cluster/health?pretty         # Vue globale
GET /_nodes/stats?pretty            # Métriques détaillées par nœud
GET /_cat/nodes?v                   # Tableau récapitulatif
GET /_cat/allocation?v              # Espace disque par nœud
GET /_cluster/allocation/explain    # Pourquoi ce shard n'est pas assigné ?
```

**_cluster/allocation/explain** est LE tool de diagnostic. Il répond à "pourquoi mon shard est UNASSIGNED ?". Causes les plus fréquentes :
1. Disque plein (disk watermark atteint)
2. Nœud absent ou en erreur
3. `max_shards_per_node` dépassé
4. Index fermé

---

## TP6 — Cluster multi-nœuds (11:30 — 60 min)

**Ce que tu dis** :
> "On passe maintenant au cluster 3 nœuds. Basculez sur docker-compose.cluster.yml. ATTENTION : ce cluster a besoin d'au moins 6 GB de RAM disponible. Vérifiez d'abord avec `docker stats`."

**Points de surveillance** :
- Nœud qui ne rejoint pas le cluster → vérifier initial_master_nodes et seed_hosts dans le docker-compose.cluster.yml
- Shards UNASSIGNED → vérifier _cluster/allocation/explain
- Ex.5 snapshot : le repository filesystem est dans /usr/share/opensearch/snapshots dans le conteneur — doit être monté comme volume

**Bonus — Simuler une panne** :
> "Pour les rapides : `docker stop opensearch-node2`. Regardez _cat/shards — les shards de node2 passent à UNASSIGNED pendant quelques secondes, puis se réattribuent sur node1 et node3. Redémarrez : `docker start opensearch-node2`. Le nœud rejoindra le cluster et récupérera ses shards."

---

## Chapitre 8 — Sécurité dans OpenSearch (13:30 — 60 min)

### Slide : Vue d'ensemble

**Timing** : 5 min

**Ce que tu dis** :
> "OpenSearch Security est natif et gratuit — c'était un avantage majeur sur Elasticsearch où la sécurité était payante jusqu'à récemment. Le Security Plugin gère deux couches distinctes : le transport (entre nœuds) et le REST (entre clients et cluster). Aux jours 1 et 2, on l'avait désactivé pour simplifier. Aujourd'hui on l'active."

---

### Slide : TLS/SSL

**Timing** : 15 min

**Ce que tu dis** :
> "TLS, c'est le HTTPS du monde OpenSearch. Sans TLS, vos données circulent en clair sur le réseau. En environnement de formation, on utilise les demo certificates qui sont déjà dans l'image Docker. En production — jamais les demo certs, les clés privées sont publiques sur GitHub."

**Question fréquente** :
- Q: "Quel est l'impact performance du TLS ?" → R: "Négligeable sur du matériel moderne. La négociation TLS est mise en cache (TLS session resumption). Le coût CPU du chiffrement symétrique AES-256 est quasi nul avec les instructions matérielles modernes."
- Q: "Comment gérer les certificats en production ?" → R: "Options : Let's Encrypt (pour le REST), CA interne d'entreprise, HashiCorp Vault pour la rotation automatique."

---

### Slide : RBAC

**Timing** : 20 min

**Ce que tu dis** :
> "RBAC, c'est simple : vous définissez des Rôles avec des Permissions, puis vous assignez ces Rôles à des Utilisateurs. Principe du moindre privilège : chaque utilisateur n'a que les permissions dont il a besoin, pas plus."

**Démo live** :
```bash
# Créer le rôle
curl -k -u admin:Admin@1234! -X PUT https://localhost:9200/_plugins/_security/api/roles/products_reader \
  -H 'Content-Type: application/json' \
  -d '{"cluster_permissions":["cluster_monitor"],"index_permissions":[{"index_patterns":["products-*"],"allowed_actions":["read"]}]}'

# Créer l'utilisateur
curl -k -u admin:Admin@1234! -X PUT https://localhost:9200/_plugins/_security/api/internalusers/analyst \
  -H 'Content-Type: application/json' \
  -d '{"password":"Analyst@1234!"}'

# Mapper
curl -k -u admin:Admin@1234! -X PUT https://localhost:9200/_plugins/_security/api/rolesmapping/products_reader \
  -H 'Content-Type: application/json' \
  -d '{"users":["analyst"]}'

# Tester (doit fonctionner)
curl -k -u analyst:Analyst@1234! https://localhost:9200/products/_search

# Tester suppression (doit retourner 403)
curl -k -u analyst:Analyst@1234! -X DELETE https://localhost:9200/products
```

---

### Slide : DLS et FLS

**Timing** : 10 min

**Ce que tu dis** :
> "Pour des besoins encore plus fins, on peut aller au niveau du document ou du champ. DLS = Document Level Security : l'utilisateur ne voit que les documents qui matchent une certaine condition. FLS = Field Level Security : certains champs sont masqués."

**Exemple DLS** :
> "Use case réel : un système multi-tenant où chaque client B2B ne voit que ses propres produits. Ou un analyste marketing qui ne voit que les données de sa région. DLS ajoute invisiblement un filtre sur chaque requête — l'utilisateur ne peut pas le contourner."

---

### Slide : Audit Logging

**Timing** : 10 min

**Ce que tu dis** :
> "L'audit logging, c'est la mémoire de votre cluster. Qui a accédé à quoi, quand. Obligatoire dans de nombreux secteurs réglementés : santé (HIPAA), finance (PCI-DSS), Europe (RGPD). OpenSearch stocke les logs d'audit dans un index dédié."

---

## TP7 — Sécurisation du cluster (14:30 — 45 min)

**Ce que tu dis** :
> "Le TP le plus complexe de la formation. Suivez les étapes dans l'ordre — chaque étape dépend de la précédente. Ouvrez labs/tp7-securite/README.md."

**Points de surveillance** :
- Oubli du flag `-k` avec curl sur HTTPS → `curl: (60) SSL certificate problem`
- Password trop simple → `validation_error: password must be at least 8 characters...`
- Mauvaise URL (http au lieu de https) → `Empty reply from server`
- User pas encore mappé → 403 même avec bon mot de passe

**Alerte** : Si un participant dit "403 Forbidden" avec le bon utilisateur → vérifier que le role mapping est bien fait : `GET /_plugins/_security/api/rolesmapping/products_reader`

---

## Récap Global — Le Fil Rouge (15:30 — 30 min)

**Ce que tu dis** :
> "Prenons un moment pour voir le chemin parcouru. Le matin du Jour 1, vous n'aviez jamais vu OpenSearch. Maintenant, vous êtes capable de déployer un cluster 3 nœuds sécurisé avec haute disponibilité, de créer des analyseurs linguistiques, de visualiser vos données, et d'administrer le tout en production."

**Le fil rouge complet** :
1. Jour 1 : cluster single-node → 1000+ produits indexés → recherche DSL et agrégations ✅
2. Jour 2 : analyseur français → autocomplétion → géolocalisation → dashboard e-commerce ✅
3. Jour 3 : cluster 3 nœuds HA → ISM + snapshots → RBAC + TLS → DLS + audit ✅

**Ressources** :
> "Documentation officielle : opensearch.org/docs/latest. Forum : forum.opensearch.org. GitHub : github.com/opensearch-project. Si vous avez un problème en prod, le forum est très actif — l'équipe AWS répond souvent."

**Checklist production** :
> "Avant de déployer en prod : 3+ nœuds master dédiés, TLS sur transport ET REST, snapshots S3 quotidiens, monitoring heap + disk, ISM pour les logs, principe du moindre privilège pour la sécurité."

---

## QCM & Satisfaction (16:00 — 30 min)

**À 16h00 EXACTEMENT** : Envoyer le lien Digiforma pour le quiz de validation et le questionnaire de satisfaction.

**Ce que tu dis** :
> "C'est l'heure du quiz de validation ! J'envoie le lien maintenant. Vous avez 20 minutes. 20 questions sur les 3 jours. La solution est dans quiz/quiz-final.md — mais ne trichez pas, c'est votre propre bénéfice d'évaluer votre niveau."

**Pendant le quiz** : Circuler, être disponible pour les questions mais ne pas donner les réponses. Observer les hésitations → sujets à approfondir si la formation continue.

**Après le quiz** :
> "Maintenant le questionnaire de satisfaction. Votre retour est précieux — il permet d'améliorer la formation pour les prochains groupes. Soyez honnêtes, positif comme négatif."

**Important** : Rappeler de signer la feuille de présence pour la dernière demi-journée !

---

## Q&A Final & Clôture (16:30 — 30 min)

**Ce que tu dis** :
> "On a encore 30 minutes. C'est votre temps. Qu'est-ce qui vous a le plus surpris dans ces 3 jours ? Qu'est-ce que vous auriez voulu approfondir ? Des questions sur votre contexte spécifique ?"

**Questions typiques en fin de formation** :
- "Comment migrer de Elasticsearch ?" → Vérifiez la compatibilité API (OS 3.x ≈ ES 7.10). Le SDK OpenSearch est recommandé. Testez votre code sur un cluster de staging.
- "Comment monitorer en production ?" → OpenSearch Dashboards a des dashboards de monitoring natifs. Prometheus + Grafana aussi. Alerting plugin pour les notifications.
- "Combien de nœuds pour notre use case ?" → Ça dépend du volume de données, du throughput d'indexation, et des SLA de disponibilité. Règle de base : minimum 3 nœuds pour la HA.

**Clôture** :
> "Merci pour ces 3 jours — votre participation et vos questions ont rendu la formation vivante. Vous avez maintenant les bases solides pour utiliser OpenSearch en production. N'hésitez pas à me contacter si vous avez des questions après la formation. Bonne continuation !"

**Rappels finaux** :
- Signer la feuille de présence !
- L'attestation de formation arrivera par Digiforma dans quelques jours
- Les fichiers de la formation restent disponibles dans le repository

---

*Guide Jour 3 — Formation OpenSearch 3.6*
