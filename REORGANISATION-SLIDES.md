# Réorganisation slides — À faire

## Changement 1 — Déplacer "Split-brain" de Jour 1 vers Jour 2 Ch.6

**Fichier source :** `opensearch-formation/slides/jour-1/index.html`
**Fichier cible :** `opensearch-formation/slides/jour-2/index.html`

### Slides à retirer de Jour 1

Retirer ces 3 blocs `<section>` (actuellement entre le Quiz CH1 et l'opener CH2) :

- `<!-- SLIDE 10e : SPLIT-BRAIN — LE PROBLÈME -->` — "Split-brain — Le cauchemar distribué"
- `<!-- SLIDE 10f : QUORUM — LA SOLUTION -->` — "Quorum — Pourquoi 3 nœuds minimum ?"
- `<!-- SLIDE 10g : CONFIGURATION SPLIT-BRAIN -->` — "Configuration OpenSearch — Anti-split-brain"

Aussi mettre à jour dans Jour 1 :
- **Quiz CH1 (slide 11)** : supprimer la question 2 "Combien de nœuds minimum pour éviter le split-brain avec 1 master ?" et son corrigé dans les notes. Il reste 3 questions.
- **Notes slide 10c** (Lucene Segments) : remplacer la transition `"Parlons maintenant d'un risque critique en production : le split-brain."` par `"Voyons maintenant qui fait quoi entre Lucene et OpenSearch."`
- **Notes slide 10d** (Lucene vs OS) : remplacer la transition `"Maintenant, un sujet critique pour la production : le split-brain."` par `"On va maintenant tester votre compréhension avec le quiz du Chapitre 1."`
- **Slide 32 Récap Jour 1** : ajouter dans le preview du lendemain : `"Split-brain &amp; Quorum"`

### Slides à ajouter dans Jour 2

Ajouter dans `jour-2/index.html` **avant le slide `<!-- SLIDE 23 : RÉCAP JOUR 2 -->`** :

1. Un opener Chapitre 6 (style `background:#7c3aed;color:#fff;`) :
   ```
   Chapitre 6
   Architecture distribuée — Split-brain & Quorum
   "Comment éviter le pire cauchemar d'un cluster en production ?"
   ```

2. Coller les 3 blocs `<section>` retirés de Jour 1 (10e, 10f, 10g) tels quels.

Mettre à jour dans Jour 2 :
- **Plan du Jour 2 (slide 3)** : ajouter dans la colonne Après-midi `📖 Ch.6 : Split-brain &amp; Quorum` après TP5
- **Récap Jour 2 (slide 23)** : ajouter une cellule `<strong>Split-brain & Quorum</strong><br>Quorum, anti-split-brain, opensearch.yml`

---

## Changement 2 — Avancer Installation + TP1 avant Architecture & Lucene

**Fichier :** `opensearch-formation/slides/jour-1/index.html`

### Ordre actuel (simplifié)

```
CH1 opener
Cas d'usage
Histoire
[8]  Architecture : les concepts clés        ← doit passer APRÈS TP1
[9]  OpenSearch vs Elasticsearch
[10] Démo Live — Architecture                ← doit passer APRÈS TP1
[10b] Lucene — Le moteur sous le capot
[10c] Lucene — Segments, refresh et merge    ← doit passer APRÈS TP1
[10d] Lucene vs OpenSearch — Qui fait quoi ?
Quiz CH1
Récap CH1
[13] CH2 opener (Installation)               ← doit avancer
[14] Prérequis
[15] Docker Compose
[16] Vérification
[17] TP1                                     ← doit avancer
CH3a ...
```

### Ordre cible

```
CH1 opener
Cas d'usage
Histoire
[9]  OpenSearch vs Elasticsearch
[13] CH2 opener (Installation)         ← avancé ici
[14] Prérequis
[15] Docker Compose
[16] Vérification
[17] TP1                               ← avancé ici
[8]  Architecture : les concepts clés  ← maintenant APRÈS TP1
[10] Démo Live — Architecture          ← maintenant APRÈS TP1
[10b] Lucene — Le moteur sous le capot
[10c] Lucene — Segments, refresh et merge  ← maintenant APRÈS TP1
[10d] Lucene vs OpenSearch — Qui fait quoi ?
Quiz CH1
Récap CH1
CH3a ...
```

### Mise à jour Plan du Jour 1 (slide 3)

Colonne Matin — ajouter `📖 Architecture &amp; Lucene` après `🔧 TP1 : Démarrage` :

```
Matin
🎯 Démo live (9h30)
📖 Chapitre 1 : Introduction
📖 Chapitre 2 : Installation
🔧 TP1 : Démarrage (11h00)
📖 Architecture & Lucene
```

---

## Fichiers concernés

| Fichier | Modifications |
|---------|---------------|
| `slides/jour-1/index.html` | Réordonnancement sections, suppression 10e/10f/10g, quiz, notes, plan, récap |
| `slides/jour-2/index.html` | Plan J2, ajout Ch6 opener + 3 slides split-brain, récap |
