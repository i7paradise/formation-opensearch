# TP7 — Analyseur français

## Objectif
Comprendre pourquoi la recherche full-text échoue sans analyseur adapté, puis le corriger : de "0 résultat" à "des dizaines de résultats" pour la même requête.

## Prérequis
- TP5 terminé, index `products` avec 1000+ documents
- Cluster OpenSearch running sur http://localhost:9200

## Durée estimée
35 minutes

## Fil conducteur

```
GET products/_search?q=name:velo
        ↓
   0 résultats   ← PROBLÈME
        ↓
   Comprendre pourquoi
        ↓
   Créer l analyseur français
        ↓
   Créer products-fr + réindexer
        ↓
GET products-fr/_search?q=name:velo
        ↓
   20+ résultats ← RÉSOLU
```

---

### Exercice 1 : Constater le problème
**Objectif** : Observer que la recherche sur `velo` ne retourne rien dans l'index actuel.

**Instructions** :
1. Chercher `velo` dans le champ `name` de l'index `products`
2. Chercher `vélo` dans `name`
3. Chercher `vélos` dans `name`
4. Comparer les counts obtenus

**Indice** : `GET /products/_search` avec `"query": { "match": { "name": "velo" } }`
**Vérification** : La requête `velo` retourne 0 résultats alors que `vélos` en retourne potentiellement quelques-uns.

---

### Exercice 2 : Comprendre la cause
**Objectif** : Inspecter la tokenisation actuelle pour comprendre pourquoi "velo" ne matche pas "Vélos".

**Instructions** :
1. Utiliser `_analyze` sur l'index `products` avec l'analyseur `standard` sur le texte `"Vélos électriques d'entrée de gamme"`
2. Observer les tokens produits : est-ce que `velo` apparaît parmi eux ?
3. Utiliser l'analyseur `french` (built-in) sur le même texte
4. Comparer les deux résultats

**Indice** : `POST /products/_analyze` avec `"analyzer": "standard"` puis `"analyzer": "french"`
**Vérification** : Avec `standard`, le token `vélos` est conservé tel quel. Avec `french`, on obtient `velo`.

---

### Exercice 3 : Créer l'analyseur français personnalisé
**Objectif** : Construire un analyseur custom adapté à notre catalogue e-commerce.

**Instructions** :
1. Créer l'index `products-fr` avec les paramètres d'analyse suivants :
   - Token filter `french_stop` : type `stop`, stopwords `_french_`
   - Token filter `french_stemmer` : type `stemmer`, language `french`
   - Analyseur `french_custom` : tokenizer `standard`, filters `[lowercase, asciifolding, french_stop, french_stemmer]`
2. Définir le mapping du champ `name` avec `"analyzer": "french_custom"`
3. Tester l'analyseur : `POST /products-fr/_analyze` sur `"Vélos électriques d'entrée de gamme"`

**Indice** : Déclarer les filters dans `settings.analysis.filter`, l'analyseur dans `settings.analysis.analyzer`
**Vérification** : Les tokens doivent inclure `velo` et `electr` (ou équivalent stemmatisé), sans "de", "d'", "entrée".

---

### Exercice 4 : Réindexer les données
**Objectif** : Copier les données de `products` vers `products-fr` pour qu'elles soient analysées avec le nouvel analyseur.

**Instructions** :
1. Utiliser `_reindex` pour copier `products` → `products-fr`
2. Vérifier que les counts sont identiques
3. Comparer les mappings des deux index sur le champ `name`

**Indice** : `POST /_reindex { "source": {"index": "products"}, "dest": {"index": "products-fr"} }`
**Vérification** : `GET /products-fr/_count` doit retourner le même nombre que `GET /products/_count`.

---

### Exercice 5 : Constater le résultat — velo trouve des vélos
**Objectif** : Valider que la même requête `velo` retourne maintenant des résultats grâce à l'analyseur.

**Instructions** :
1. Chercher `velo` dans `products-fr._search` → doit retourner des documents
2. Chercher `velo` dans `products._search` → toujours 0
3. Chercher `electrique` (sans accent) dans `products-fr` → doit matcher "électrique"
4. Chercher `ordinateur` dans `products-fr` → doit matcher "ordinateurs"

**Indice** : `GET /products-fr/_search` avec `"query": { "match": { "name": "velo" } }`
**Vérification** : Au moins 10 résultats pour `velo` dans `products-fr` contre 0 dans `products`.

---

## Vérification finale
- [ ] Exercice 1 : `velo` → 0 résultats dans `products` (confirmé)
- [ ] Exercice 2 : `_analyze` avec `standard` vs `french` — différence visible sur les tokens
- [ ] Exercice 3 : `products-fr` créé, `_analyze` produit le token `velo`
- [ ] Exercice 4 : counts identiques entre `products` et `products-fr`
- [ ] Exercice 5 : `velo` → 10+ résultats dans `products-fr`

*Passez au [TP8 — Cluster 3 nœuds](../tp8-cluster-3noeuds/README.md)*
