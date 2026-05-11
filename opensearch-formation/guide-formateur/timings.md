# Planning détaillé — 3 jours de formation OpenSearch 3.6

| Jour | Heure | Durée | Activité | Type |
|------|-------|-------|----------|------|
| Jour 1 | 09:00–09:30 | 30 min | Accueil, présentation, tour de table | Q/A |
| Jour 1 | 09:30–09:45 | 15 min | Démo live ice breaker | Démo live |
| Jour 1 | 09:45–10:20 | 35 min | Chapitre 1 : Introduction à OpenSearch (allégé) | Cours |
| Jour 1 | 10:20–10:30 | 10 min | Chapitre 2 : Installation — Docker Compose uniquement | Cours |
| Jour 1 | 10:30–11:15 | 45 min | TP1 : Installation en local | TP |
| Jour 1 | 11:15–11:30 | 15 min | Pause | Pause |
| Jour 1 | 11:30–12:00 | 30 min | Chapitre 3a : Mappings & types de champs | Cours |
| Jour 1 | 12:00–12:30 | 30 min | TP2 : Créer un index complet (nouveau) | TP |
| Jour 1 | 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| Jour 1 | 13:30–14:15 | 45 min | Chapitre 3b : API REST, CRUD, Bulk API & bonnes pratiques | Cours |
| Jour 1 | 14:15–15:00 | 45 min | TP3 : CRUD, Bulk API & bonnes pratiques | TP |
| Jour 1 | 15:00–15:15 | 15 min | Pause | Pause |
| Jour 1 | 15:15–15:45 | 30 min | Chapitre 3c : Query DSL (sans agrégations) | Cours |
| Jour 1 | 15:45–16:30 | 45 min | TP4 : Requêtes & Recherche (sans agrégations) | TP |
| Jour 1 | 16:30–17:00 | 30 min | Récap Jour 1, Q&A, preview Jour 2 | Q/A |
| Jour 2 | 09:00–09:45 | 45 min | Chapitre 8 : Sécurité (RBAC, DLS, FLS — sans TLS détaillé) | Cours |
| Jour 2 | 09:45–10:00 | 15 min | Pause | Pause |
| Jour 2 | 10:00–10:30 | 30 min | TP5 : Sécurisation RBAC + FLS | TP |
| Jour 2 | 10:30–11:30 | 60 min | Chapitre 4 : Fonctionnalités avancées (pipelines, analyseurs, highlight) | Cours |
| Jour 2 | 11:30–12:30 | 60 min | TP6 : Pipelines & Analyseurs | TP |
| Jour 2 | 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| Jour 2 | 13:30–14:45 | 75 min | Chapitre 6 : Architecture & Cluster (Lucene, nœuds, routing, scalabilité) | Cours |
| Jour 2 | 14:45–15:30 | 45 min | TP7 : Installation cluster 3 nœuds | TP |
| Jour 2 | 15:30–15:45 | 15 min | Pause | Pause |
| Jour 2 | 15:45–16:30 | 45 min | TP8 : Routage — démonstration (nouveau) | TP |
| Jour 2 | 16:30–17:00 | 30 min | Récap Jour 2, Q&A, preview Jour 3 | Q/A |
| Jour 3 | 09:00–10:00 | 60 min | Chapitre 5 : Agrégations complètes | Cours |
| Jour 3 | 10:00–10:15 | 15 min | Pause | Pause |
| Jour 3 | 10:15–11:30 | 75 min | TP9 : Agrégations avancées (nouveau) | TP |
| Jour 3 | 11:30–12:15 | 45 min | Chapitre 5b : Scoring BM25, _explain, search_after, optimisation | Cours |
| Jour 3 | 12:15–12:30 | 15 min | Démo live Agrégations | Démo live |
| Jour 3 | 12:30–13:30 | 60 min | Déjeuner | Déjeuner |
| Jour 3 | 13:30–14:15 | 45 min | Chapitre 9 : OpenSearch Dashboards | Cours |
| Jour 3 | 14:15–15:00 | 45 min | TP10 : Dashboard e-commerce | TP |
| Jour 3 | 15:00–15:15 | 15 min | Pause | Pause |
| Jour 3 | 15:15–16:00 | 45 min | Chapitre 10 : Reindex & Cycle de vie (Reindex, ISM, Snapshots) | Cours |
| Jour 3 | 16:00–16:30 | 30 min | TP11 : Reindex + ISM | TP |
| Jour 3 | 16:30–17:00 | 30 min | Récap global 3 jours + QCM + Satisfaction + Q&A | Q/A + QCM |

---

## Récapitulatif par jour

| Jour | Cours | TP | Pauses + Déjeuner | Q/A + QCM | Total |
|------|-------|----|-------------------|-----------|-------|
| Jour 1 | 2h00 | 2h45 | 1h45 | 30 min | 7h00 |
| Jour 2 | 3h00 | 2h30 | 1h30 | — | 7h00 |
| Jour 3 | 2h30 | 2h30 | 1h30 | 30 min | 7h00 |
| **Total** | **7h30** | **7h45** | **4h45** | **1h00** | **21h00** |

---

## Résumé des 11 TPs

| TP | Titre | Durée | Jour |
|----|-------|-------|------|
| TP1 | Installation en local | 45 min | J1 matin |
| TP2 | Créer un index complet (nouveau) | 30 min | J1 matin |
| TP3 | CRUD, Bulk API & bonnes pratiques | 45 min | J1 après-midi |
| TP4 | Requêtes & Recherche | 45 min | J1 après-midi |
| TP5 | Sécurisation RBAC + FLS | 30 min | J2 matin |
| TP6 | Pipelines & Analyseurs | 60 min | J2 matin |
| TP7 | Installation cluster 3 nœuds | 45 min | J2 après-midi |
| TP8 | Routage — démonstration (nouveau) | 45 min | J2 après-midi |
| TP9 | Agrégations avancées (nouveau) | 75 min | J3 matin |
| TP10 | Dashboard e-commerce | 45 min | J3 après-midi |
| TP11 | Reindex + ISM | 30 min | J3 après-midi |

---

## Notes organisationnelles

- **Feuilles de présence** : faire signer en début de matinée et en début d'après-midi (4 demi-journées par jour × 3 jours = 12 signatures par stagiaire).
- **Lien QCM Digiforma** : envoyer le lien par e-mail ou via le chat à 16h30 le Jour 3.
- **Questionnaire de satisfaction** : distribuer (papier ou Digiforma) juste après le QCM.
- **Support de cours** : mettre les slides en PDF sur le drive partagé avant 9h00 chaque matin.
- **Environnement** : vérifier que Docker Compose est opérationnel sur chaque poste avant 8h45.
- **TPs optionnels** : Géolocalisation et Completion Suggester disponibles pour les groupes rapides.
