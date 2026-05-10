# TP7 — Sécurisation du cluster OpenSearch

## Informations générales

| Paramètre  | Valeur                                               |
|------------|------------------------------------------------------|
| Durée      | 45 minutes                                           |
| Difficulté | Avancé                                               |
| Prérequis  | TP6 terminé, cluster 3 nœuds démarré avec le plugin de sécurité activé |
| Objectif   | TLS + RBAC + Audit Logging en production             |

## Objectif

Sécuriser un cluster OpenSearch en mettant en place le chiffrement TLS pour les communications, le contrôle d'accès basé sur les rôles (RBAC) pour les utilisateurs, et l'audit logging pour la conformité.

## Contexte

Notre cluster e-commerce est actuellement accessible sans authentification — une situation inacceptable pour un environnement de production. Vous allez déployer une sécurité en profondeur : chiffrement des communications, isolation des données par rôle, et traçabilité des accès.

## Architecture de sécurité cible

```
         Client (curl/Dashboards)
                 │
                 │  HTTPS (TLS)
                 ▼
     ┌───────────────────────┐
     │    Load Balancer      │
     └───────────┬───────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
  opensearch-node1   opensearch-node2
  [TLS inter-nœuds]  [TLS inter-nœuds]
        │                 │
        └────────┬────────┘
                 │
     ┌───────────▼───────────┐
     │   Security Plugin     │
     │  ┌─────────────────┐  │
     │  │ Authentication  │  │
     │  │ (admin, analyst)│  │
     │  ├─────────────────┤  │
     │  │   RBAC          │  │
     │  │ (roles/tenants) │  │
     │  ├─────────────────┤  │
     │  │  Audit Logging  │  │
     │  └─────────────────┘  │
     └───────────────────────┘
```

---

## Exercice 1 — Activer le plugin de sécurité

### 1.1 Vérifier la configuration actuelle

```bash
# Vérifier si la sécurité est actuellement désactivée
docker exec opensearch-node1 cat /usr/share/opensearch/config/opensearch.yml | grep -i security
```

Si vous voyez `DISABLE_SECURITY_PLUGIN=true`, la sécurité est désactivée.

### 1.2 Modifier le docker-compose

Éditez `infrastructure/docker-compose.cluster.yml`. Pour chaque service opensearch, **retirez** la variable d'environnement suivante :

```yaml
# Supprimer cette ligne dans chaque service opensearch :
- DISABLE_SECURITY_PLUGIN=true
```

### 1.3 Redémarrer le cluster

```bash
docker compose -f infrastructure/docker-compose.cluster.yml down
docker compose -f infrastructure/docker-compose.cluster.yml up -d
```

### 1.4 Tester avec l'authentification

```bash
# Sans authentification : doit échouer avec 401
curl -X GET "https://localhost:9200/" -k

# Avec authentification admin : doit réussir
curl -X GET "https://localhost:9200/" -k -u admin:admin
```

> **Note** : Le flag `-k` (`--insecure`) est utilisé pour contourner la validation du certificat auto-signé dans cet environnement de formation. En production, utilisez toujours un certificat valide.

---

## Exercice 2 — Configurer TLS avec les certificats de démonstration

### 2.1 Comprendre les deux couches TLS

OpenSearch Security utilise deux couches TLS distinctes :

| Couche       | Objet                                  | Port |
|--------------|----------------------------------------|------|
| Transport TLS| Communication inter-nœuds (cluster)    | 9300 |
| REST TLS     | Communication client → nœud (API)      | 9200 |

### 2.2 Vérifier les certificats de démonstration

```bash
# Lister les certificats présents
docker exec opensearch-node1 ls /usr/share/opensearch/config/

# Vérifier le certificat du nœud
docker exec opensearch-node1 openssl x509 -in /usr/share/opensearch/config/esnode.pem -noout -text | grep -E "Subject:|Issuer:|Not After"
```

### 2.3 Vérifier la configuration TLS dans opensearch.yml

```bash
docker exec opensearch-node1 cat /usr/share/opensearch/config/opensearch.yml
```

Les paramètres TLS clés que vous devez voir :
```yaml
# TLS Transport (inter-nœuds)
plugins.security.ssl.transport.pemcert_filepath:    esnode.pem
plugins.security.ssl.transport.pemkey_filepath:     esnode-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: root-ca.pem
plugins.security.ssl.transport.enforce_hostname_verification: false

# TLS REST (clients)
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath:    esnode.pem
plugins.security.ssl.http.pemkey_filepath:     esnode-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: root-ca.pem
```

### 2.4 Vérifier la connexion TLS

```bash
# Vérifier les informations du certificat présenté par le serveur
openssl s_client -connect localhost:9200 -showcerts 2>/dev/null | openssl x509 -noout -text | grep -E "Subject:|Issuer:|Not After"

# Test de connexion HTTPS
curl -X GET "https://localhost:9200/_cluster/health?pretty" -k -u admin:admin
```

---

## Exercice 3 — Se connecter en tant qu'admin

### 3.1 Tester l'accès avec les identifiants par défaut

```bash
# Informations du cluster
curl -X GET "https://localhost:9200/" -k -u admin:admin

# État du plugin de sécurité
curl -X GET "https://localhost:9200/_plugins/_security/health?pretty" -k -u admin:admin

# Informations sur l'utilisateur connecté
curl -X GET "https://localhost:9200/_plugins/_security/authinfo?pretty" -k -u admin:admin
```

### 3.2 Lister les utilisateurs et rôles existants

```bash
# Lister les utilisateurs internes
curl -X GET "https://localhost:9200/_plugins/_security/api/internalusers?pretty" -k -u admin:admin

# Lister les rôles
curl -X GET "https://localhost:9200/_plugins/_security/api/roles?pretty" -k -u admin:admin

# Lister les mappings de rôles
curl -X GET "https://localhost:9200/_plugins/_security/api/rolesmapping?pretty" -k -u admin:admin
```

### 3.3 Changer le mot de passe admin (obligatoire en production)

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/admin" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "password": "Admin@SecureP@ss2026!",
    "backend_roles": ["admin"],
    "attributes": {}
  }'
```

> **Important** : En production, changez TOUJOURS le mot de passe admin par défaut immédiatement après l'installation.

---

## Exercice 4 — Créer le rôle `products_reader`

Le rôle `products_reader` doit permettre uniquement de lire les index `products-*` sans pouvoir écrire, modifier ou supprimer.

### 4.1 Créer le rôle

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:admin \
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

### 4.2 Vérifier la création du rôle

```bash
curl -X GET "https://localhost:9200/_plugins/_security/api/roles/products_reader?pretty" \
  -k -u admin:admin
```

---

## Exercice 5 — Créer l'utilisateur `analyst` et mapper au rôle

### 5.1 Créer l'utilisateur analyst

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/analyst" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "password":      "Analyst@Pass2026!",
    "backend_roles": [],
    "attributes": {
      "department": "analytics",
      "access_level": "read-only"
    }
  }'
```

### 5.2 Mapper l'utilisateur au rôle products_reader

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/rolesmapping/products_reader" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "backend_roles": [],
    "hosts":         [],
    "users":         ["analyst"]
  }'
```

### 5.3 Vérifier le mapping

```bash
curl -X GET "https://localhost:9200/_plugins/_security/api/rolesmapping/products_reader?pretty" \
  -k -u admin:admin
```

---

## Exercice 6 — Tester les permissions

### 6.1 Tester l'accès en lecture (doit réussir)

```bash
# Rechercher des produits — DOIT réussir
curl -X GET "https://localhost:9200/products/_search?pretty" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} }, "size": 3 }'

# Obtenir un document — DOIT réussir
curl -X GET "https://localhost:9200/products/_doc/1?pretty" \
  -k -u analyst:Analyst@Pass2026!

# Compter les documents — DOIT réussir
curl -X GET "https://localhost:9200/products/_count" \
  -k -u analyst:Analyst@Pass2026!
```

### 6.2 Tester l'accès en écriture (doit échouer avec 403)

```bash
# Indexer un document — DOIT échouer (403 Forbidden)
curl -X POST "https://localhost:9200/products/_doc" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "name": "Test produit", "price": 10.00 }'

# Supprimer un document — DOIT échouer (403 Forbidden)
curl -X DELETE "https://localhost:9200/products/_doc/1" \
  -k -u analyst:Analyst@Pass2026!

# Supprimer l'index — DOIT échouer (403 Forbidden)
curl -X DELETE "https://localhost:9200/products" \
  -k -u analyst:Analyst@Pass2026!
```

**Résultat attendu pour les opérations d'écriture :**
```json
{
  "error": {
    "root_cause": [
      {
        "type":   "security_exception",
        "reason": "no permissions for [indices:data/write/index] and User [name=analyst, ...] roles=[products_reader]"
      }
    ]
  },
  "status": 403
}
```

### 6.3 Tester l'accès à un autre index (doit échouer)

```bash
# L'analyst n'a pas accès aux index de logs
curl -X GET "https://localhost:9200/.opensearch-security/_search" \
  -k -u analyst:Analyst@Pass2026!
```

---

## Exercice 7 — Activer l'audit logging

### 7.1 Activer l'audit logging via l'API

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/audit/config" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "audit": {
      "enable_rest":            true,
      "disabled_rest_categories": ["AUTHENTICATED", "SSL_EXCEPTION"],
      "enable_transport":       true,
      "disabled_transport_categories": ["GRANTED_PRIVILEGES"],
      "resolve_bulk_requests":  true,
      "log_request_body":       true,
      "resolve_indices":        true,
      "exclude_sensitive_headers": true
    },
    "compliance": {
      "enabled":             true,
      "write_log_diffs":     true,
      "read_watched_fields": {},
      "write_watched_indices": ["products", "products-*"]
    }
  }'
```

### 7.2 Générer des événements d'audit

```bash
# Connexion réussie (génère un log AUTHENTICATED)
curl -X GET "https://localhost:9200/" -k -u analyst:Analyst@Pass2026!

# Tentative d'écriture non autorisée (génère un log MISSING_PRIVILEGES)
curl -X POST "https://localhost:9200/products/_doc" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "name": "Test", "price": 1.00 }'

# Connexion avec mauvais mot de passe (génère un log FAILED_LOGIN)
curl -X GET "https://localhost:9200/" -k -u analyst:mauvais-mot-de-passe
```

### 7.3 Vérifier les logs d'audit

```bash
# Les logs d'audit sont écrits dans un index .opensearch-security-audit
curl -X GET "https://localhost:9200/.opensearch-security-audit*/_search?pretty" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "match_all": {} },
    "sort":  [{ "@timestamp": { "order": "desc" } }],
    "size":  10,
    "_source": ["@timestamp", "audit_category", "audit_request_remote_address",
                "audit_request_body", "audit_cluster_name", "audit_node_name",
                "audit_trace_resolved_indices"]
  }'
```

### 7.4 Filtrer les événements par catégorie

```bash
# Voir uniquement les tentatives de connexion échouées
curl -X GET "https://localhost:9200/.opensearch-security-audit*/_search?pretty" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "term": { "audit_category": "FAILED_LOGIN" }
    },
    "size": 5
  }'

# Voir les accès non autorisés
curl -X GET "https://localhost:9200/.opensearch-security-audit*/_search?pretty" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "term": { "audit_category": "MISSING_PRIVILEGES" }
    },
    "size": 5
  }'
```

---

## TP Bonus — Document Level Security (DLS)

L'objectif est de configurer le rôle `products_reader` pour que l'utilisateur `analyst` ne voie que les produits de la catégorie `Électronique`, même si l'index contient d'autres catégories.

### Modifier le rôle avec un filtre DLS

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "cluster_permissions": [
      "cluster:monitor/health",
      "cluster:monitor/state"
    ],
    "index_permissions": [
      {
        "index_patterns": ["products-*", "products"],
        "dls": "{\"term\": {\"category\": \"Électronique\"}}",
        "fls":            [],
        "masked_fields":  [],
        "allowed_actions": ["read"]
      }
    ],
    "tenant_permissions": []
  }'
```

### Tester le filtrage DLS

```bash
# L'analyst ne doit voir QUE les produits Électronique
curl -X GET "https://localhost:9200/products/_search?pretty" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} }, "size": 10 }'

# Vérification : tenter de récupérer un produit Vêtements directement
curl -X GET "https://localhost:9200/products/_doc/DOCUMENT_ID_VETEMENT" \
  -k -u analyst:Analyst@Pass2026!
```

**Résultat attendu :** Seuls les produits avec `category: "Électronique"` apparaissent, même avec `match_all`. Les produits d'autres catégories sont invisibles pour cet utilisateur.

### (Optionnel) Field Level Security (FLS)

Pour masquer le champ `price` pour l'analyst :

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:admin \
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

> Le préfixe `~` signifie "exclure ce champ". Le champ `price` n'apparaîtra plus dans les résultats pour l'utilisateur `analyst`.

---

## Vérification finale

A la fin de ce TP, vous devez avoir :

- [ ] Plugin de sécurité activé (variable `DISABLE_SECURITY_PLUGIN` retirée)
- [ ] TLS configuré sur les couches REST et Transport
- [ ] Connexion admin vérifiée avec `-u admin:admin`
- [ ] Rôle `products_reader` créé avec permissions lecture seule
- [ ] Utilisateur `analyst` créé et mappé au rôle
- [ ] Tests lecture (succès) et écriture (échec 403) effectués
- [ ] Audit logging activé et événements générés + vérifiés
- [ ] (Bonus) DLS configuré — analyst voit uniquement catégorie Électronique

---

## Ressources

- [Security Plugin OpenSearch](https://opensearch.org/docs/latest/security/)
- [API REST Security Plugin](https://opensearch.org/docs/latest/security/access-control/api/)
- [Document Level Security (DLS)](https://opensearch.org/docs/latest/security/access-control/document-level-security/)
- [Field Level Security (FLS)](https://opensearch.org/docs/latest/security/access-control/field-level-security/)
- [Audit Logging](https://opensearch.org/docs/latest/security/audit-logs/index/)
