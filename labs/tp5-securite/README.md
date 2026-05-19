# TP5 — Sécurisation du cluster OpenSearch (RBAC + FLS)

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 30 minutes                                           |
| Difficulté | Intermédiaire                                        |
| Prérequis  | TP4 terminé, stack sécurité démarrée (`docker-compose.security.yml`) |
| Objectif   | RBAC (rôles, permissions) + FLS (masquage de champ)  |

## Démarrage du stack sécurité

Ce TP utilise `docker-compose.security.yml` — un nœud unique avec le plugin sécurité activé et des certificats TLS auto-signés. Il expose les **mêmes ports** que le stack principal (9200, 5601) : il faut donc arrêter l'autre stack avant de démarrer celui-ci.

```bash
# 1. Arrêter le stack principal (si démarré)
docker compose -f infrastructure/docker-compose.yml down

# 2. Démarrer le stack sécurité
docker compose -f infrastructure/docker-compose.security.yml up -d

# 3. Attendre ~30 secondes le démarrage du plugin sécurité, puis vérifier
curl -k -u admin:Formation@OpenSearch2024! \
  https://localhost:9200/_cluster/health?pretty

# 4. Charger les données de démonstration
./scripts/seed-data-with-security.sh
```

> **Dashboards** est accessible sur [http://localhost:5601](http://localhost:5601) — login `admin` / `Formation@OpenSearch2024!`

---

## Objectif

Sécuriser l'accès au cluster OpenSearch en créant des utilisateurs et des rôles avec des permissions précises, et en masquant des champs sensibles par rôle (Field Level Security).

## Contexte

Le cluster 3 nœuds de TP7 doit maintenant être sécurisé pour la production. On distingue deux types d'utilisateurs :
- **admin** : accès total
- **analyst** : lecture seule sur `products-*`, sans voir le champ `price`

## Architecture de sécurité cible

```
Client (curl/Dashboards)
        │
        │  HTTPS (-k pour les certs auto-signés en formation)
        ▼
Security Plugin
  ┌─────────────────┐
  │ Authentication  │  admin / analyst
  ├─────────────────┤
  │   RBAC          │  products_reader (read-only)
  ├─────────────────┤
  │   FLS           │  masquer le champ price pour analyst
  └─────────────────┘
```

---

## Exercice 1 — Se connecter en tant qu'admin

```bash
# Vérifier l'état du plugin de sécurité
curl -X GET "https://localhost:9200/_plugins/_security/health?pretty" \
  -k -u admin:Formation@OpenSearch2024!

# Informations sur l'utilisateur connecté
curl -X GET "https://localhost:9200/_plugins/_security/authinfo?pretty" \
  -k -u admin:Formation@OpenSearch2024!

# Lister les utilisateurs existants
curl -X GET "https://localhost:9200/_plugins/_security/api/internalusers?pretty" \
  -k -u admin:Formation@OpenSearch2024!
```

---

## Exercice 2 — Créer le rôle `products_reader`

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_permissions": [
      "cluster:monitor/health",
      "cluster:monitor/state",
      "cluster:monitor/nodes/info"
    ],
    "index_permissions": [
      {
        "index_patterns": ["products-*", "products"],
        "dls":            "",
        "fls":            [],
        "masked_fields":  [],
        "allowed_actions": [
          "read",
          "indices:data/read/search",
          "indices:data/read/get",
          "indices:data/read/mget*",
          "indices:admin/mappings/get",
          "indices:admin/get"
        ]
      }
    ],
    "tenant_permissions": []
  }'
```

Vérifier :
```bash
curl -X GET "https://localhost:9200/_plugins/_security/api/roles/products_reader?pretty" \
  -k -u admin:Formation@OpenSearch2024!
```

---

## Exercice 3 — Créer l'utilisateur `analyst` et mapper au rôle

```bash
# Créer l'utilisateur
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/analyst" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "password":      "Analyst@Pass2026!",
    "backend_roles": [],
    "attributes": { "department": "analytics" }
  }'

# Mapper au rôle
curl -X PUT "https://localhost:9200/_plugins/_security/api/rolesmapping/products_reader" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{ "backend_roles": [], "hosts": [], "users": ["analyst"] }'
```

---

## Exercice 4 — Tester les permissions

### 4.1 Lecture (doit réussir)
```bash
curl -X GET "https://localhost:9200/products/_search?pretty" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} }, "size": 3 }'
```

### 4.2 Écriture (doit échouer avec 403)
```bash
curl -X POST "https://localhost:9200/products/_doc" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "name": "Test", "price": 10.00 }'
```

---

## Exercice 5 — Field Level Security (FLS) — Masquer le champ `price`

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_permissions": ["cluster:monitor/health"],
    "index_permissions": [
      {
        "index_patterns": ["products-*", "products"],
        "dls":            "",
        "fls":            ["~price"],
        "masked_fields":  [],
        "allowed_actions": ["read"]
      }
    ],
    "tenant_permissions": []
  }'
```

> Le préfixe `~` signifie "exclure ce champ". Vérifier que `price` n'apparaît plus dans les résultats pour `analyst`.

---

## TP Bonus — Document Level Security (DLS)

L'analyst ne voit que la catégorie `Électronique` :

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_permissions": ["cluster:monitor/health"],
    "index_permissions": [
      {
        "index_patterns": ["products-*", "products"],
        "dls": "{\"term\": {\"category\": \"Électronique\"}}",
        "fls": ["~price"],
        "masked_fields":  [],
        "allowed_actions": ["read"]
      }
    ],
    "tenant_permissions": []
  }'
```

---

## Vérification finale

- [ ] Connexion admin vérifiée
- [ ] Rôle `products_reader` créé avec permissions lecture seule
- [ ] Utilisateur `analyst` créé et mappé au rôle
- [ ] Tests lecture (succès) et écriture (échec 403) effectués
- [ ] FLS configuré — champ `price` masqué pour `analyst`
- [ ] (Bonus) DLS configuré — `analyst` voit uniquement catégorie Électronique

---

## Ressources

- [Security Plugin OpenSearch](https://opensearch.org/docs/latest/security/)
- [Field Level Security (FLS)](https://opensearch.org/docs/latest/security/access-control/field-level-security/)
- [Document Level Security (DLS)](https://opensearch.org/docs/latest/security/access-control/document-level-security/)

*Passez au [TP6 — Pipelines & Analyseurs](../tp6-fonctionnalites-avancees/README.md)*
