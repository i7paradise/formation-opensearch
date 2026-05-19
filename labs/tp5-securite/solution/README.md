# TP7 — Solution complète : Sécurisation du cluster

## Exercice 1 — Activation du plugin de sécurité

### Modification du docker-compose.cluster.yml

Dans chaque service opensearch du fichier `docker-compose.cluster.yml`, supprimer la ligne :

```yaml
# AVANT (sécurité désactivée)
environment:
  - DISABLE_SECURITY_PLUGIN=true
  - cluster.name=opensearch-cluster
  # ...

# APRÈS (sécurité activée)
environment:
  - cluster.name=opensearch-cluster
  # ... (DISABLE_SECURITY_PLUGIN supprimé)
```

### Redémarrage et vérification

```bash
docker compose -f infrastructure/docker-compose.cluster.yml down
docker compose -f infrastructure/docker-compose.cluster.yml up -d

# Test sans auth → 401 Unauthorized
curl -X GET "https://localhost:9200/" -k
# Réponse attendue : HTTP 401

# Test avec auth → 200 OK
curl -X GET "https://localhost:9200/" -k -u admin:Formation@OpenSearch2024!
```

---

## Exercice 2 — Configuration TLS

### Certificats de démonstration OpenSearch

OpenSearch embarque des certificats auto-signés à des fins de démonstration :

| Fichier              | Rôle                                     |
|----------------------|------------------------------------------|
| `root-ca.pem`        | Autorité de certification racine         |
| `esnode.pem`         | Certificat du nœud (transport + REST)    |
| `esnode-key.pem`     | Clé privée du nœud                       |
| `kirk.pem`           | Certificat admin (pour securityadmin.sh) |
| `kirk-key.pem`       | Clé privée admin                         |

### Configuration opensearch.yml complète

```yaml
# Identité du cluster et du nœud
cluster.name: opensearch-cluster
node.name: opensearch-node1
network.host: 0.0.0.0

# Plugin de sécurité
plugins.security.disabled: false

# TLS Transport (port 9300, inter-nœuds)
plugins.security.ssl.transport.pemcert_filepath:          esnode.pem
plugins.security.ssl.transport.pemkey_filepath:           esnode-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath:    root-ca.pem
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.transport.resolve_hostname:          false

# TLS REST (port 9200, clients)
plugins.security.ssl.http.enabled:                        true
plugins.security.ssl.http.pemcert_filepath:               esnode.pem
plugins.security.ssl.http.pemkey_filepath:                esnode-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath:         root-ca.pem

# Nœuds admin autorisés à appeler l'API d'administration
plugins.security.authcz.admin_dn:
  - "CN=kirk,OU=client,O=client,L=test,C=de"

# Nœuds de confiance pour le transport TLS
plugins.security.nodes_dn:
  - "CN=opensearch.example.com,OU=node,O=node,L=test,C=de"
```

### Vérification TLS en ligne de commande

```bash
# Vérifier le certificat présenté par le serveur
echo | openssl s_client -connect localhost:9200 -showcerts 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates

# Exemple de sortie :
# subject= /C=de/L=test/O=node/OU=node/CN=opensearch.example.com
# issuer=  /C=de/L=test/O=opensearch/OU=ca/CN=root.ca.example.com
# notBefore=Jan 15 09:00:00 2025 GMT
# notAfter=Jan 14 09:00:00 2027 GMT
```

---

## Exercice 3 — Connexion admin

### Informations d'authentification par défaut

| Utilisateur | Mot de passe | Rôle          |
|-------------|-------------|---------------|
| `admin`     | `Formation@OpenSearch2024!` | Superadmin    |
| `kibanaserver` | `kibanaserver` | Dashboards service |
| `kibanaro`  | `kibanaro`  | Dashboards lecture |
| `logstash`  | `logstash`  | Ingestion     |
| `readall`   | `readall`   | Lecture globale |
| `snapshotrestore` | `snapshotrestore` | Snapshots |

### Commandes de vérification

```bash
# Informations sur l'utilisateur connecté
curl -X GET "https://localhost:9200/_plugins/_security/authinfo?pretty" -k -u admin:Formation@OpenSearch2024!
```

**Réponse :**
```json
{
  "user":              "User [name=admin, backend_roles=[admin], requestedTenant=null]",
  "user_name":         "admin",
  "user_requested_tenant": null,
  "remote_address":    "172.18.0.1:54321",
  "backend_roles":     ["admin"],
  "custom_attribute_names": [],
  "roles":             ["all_access", "own_index"],
  "tenants":           { "admin_tenant": true, "global_tenant": true },
  "principal":         null,
  "peer_certificates": "0",
  "sso_logout_url":    null
}
```

### Changer le mot de passe admin

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/admin" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "password":      "Admin@SecureP@ss2026!",
    "backend_roles": ["admin"],
    "attributes":    {}
  }'
```

**Réponse attendue :** `{"status":"OK","message":"'admin' updated."}`

---

## Exercice 4 — Rôle `products_reader`

### Commande de création

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

### Table des actions importantes

| Action String                             | Opération HTTP           |
|------------------------------------------|--------------------------|
| `read`                                   | Alias pour plusieurs actions de lecture |
| `indices:data/read/search`               | `GET /index/_search`     |
| `indices:data/read/get`                  | `GET /index/_doc/id`     |
| `indices:data/write/index`               | `PUT /index/_doc/id`     |
| `indices:data/write/delete`              | `DELETE /index/_doc/id`  |
| `indices:admin/create`                   | `PUT /index`             |
| `indices:admin/delete`                   | `DELETE /index`          |
| `cluster:admin/snapshot/create`          | `PUT /_snapshot/...`     |

---

## Exercice 5 — Utilisateur `analyst`

### Création de l'utilisateur

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/analyst" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "password":      "Analyst@Pass2026!",
    "backend_roles": [],
    "attributes": {
      "department":    "analytics",
      "access_level":  "read-only"
    }
  }'
```

**Réponse :** `{"status":"CREATED","message":"'analyst' created."}`

### Mapping au rôle

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/rolesmapping/products_reader" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "backend_roles": [],
    "hosts":         [],
    "users":         ["analyst"]
  }'
```

**Réponse :** `{"status":"CREATED","message":"'products_reader' created."}`

### Vérification de l'authentification de l'analyst

```bash
curl -X GET "https://localhost:9200/_plugins/_security/authinfo?pretty" \
  -k -u analyst:Analyst@Pass2026!
```

**Réponse :**
```json
{
  "user_name": "analyst",
  "backend_roles": [],
  "roles": ["products_reader"],
  "tenants": { "global_tenant": true }
}
```

---

## Exercice 6 — Tests des permissions

### Matrice de test complète

| Opération                              | Utilisateur | Résultat attendu | Code HTTP |
|----------------------------------------|-------------|-----------------|-----------|
| `GET /products/_search`                | analyst     | Succès          | 200       |
| `GET /products/_doc/1`                 | analyst     | Succès          | 200       |
| `GET /products/_count`                 | analyst     | Succès          | 200       |
| `POST /products/_doc`                  | analyst     | Interdit        | 403       |
| `DELETE /products/_doc/1`              | analyst     | Interdit        | 403       |
| `DELETE /products`                     | analyst     | Interdit        | 403       |
| `PUT /products/_mapping`               | analyst     | Interdit        | 403       |
| `GET /.opensearch-security/_search`    | analyst     | Interdit        | 403       |

### Commandes de test

```bash
# Test 1 : Lecture → 200 OK
curl -s -o /dev/null -w "%{http_code}" \
  "https://localhost:9200/products/_search" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{"query":{"match_all":{}},"size":1}'
# Doit afficher : 200

# Test 2 : Écriture → 403 Forbidden
curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://localhost:9200/products/_doc" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","price":1.00}'
# Doit afficher : 403

# Test 3 : Suppression → 403 Forbidden
curl -s -o /dev/null -w "%{http_code}" \
  -X DELETE "https://localhost:9200/products/_doc/1" \
  -k -u analyst:Analyst@Pass2026!
# Doit afficher : 403
```

---

## Exercice 7 — Audit Logging

### Activation

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/audit/config" \
  -k -u admin:Formation@OpenSearch2024! \
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
      "enabled":              true,
      "write_log_diffs":      true,
      "read_watched_fields":  {},
      "write_watched_indices": ["products", "products-*"]
    }
  }'
```

### Catégories d'audit disponibles

| Catégorie              | Déclencheur                                              |
|------------------------|----------------------------------------------------------|
| `FAILED_LOGIN`         | Authentification échouée (mauvais mot de passe)         |
| `MISSING_PRIVILEGES`   | Action non autorisée pour l'utilisateur                  |
| `AUTHENTICATED`        | Connexion réussie                                        |
| `GRANTED_PRIVILEGES`   | Action autorisée exécutée                                |
| `SSL_EXCEPTION`        | Erreur de certificat TLS                                 |
| `BAD_HEADERS`          | En-têtes de sécurité manquants ou invalides              |
| `INDEX_EVENT`          | Création/suppression d'index (compliance)                |
| `DOCUMENT_READ`        | Lecture de document (compliance write_watched)           |

### Requête de recherche dans les logs d'audit

```bash
curl -X GET "https://localhost:9200/.opensearch-security-audit*/_search?pretty" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          {
            "terms": {
              "audit_category": ["FAILED_LOGIN", "MISSING_PRIVILEGES"]
            }
          }
        ]
      }
    },
    "sort":  [{ "@timestamp": { "order": "desc" } }],
    "size":  20,
    "_source": [
      "@timestamp",
      "audit_category",
      "audit_request_remote_address",
      "audit_trace_resolved_indices",
      "audit_request_body"
    ]
  }'
```

---

## Bonus — Document Level Security (DLS)

### Rôle avec filtre DLS

```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/products_reader" \
  -k -u admin:Formation@OpenSearch2024! \
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

### Principe de fonctionnement du DLS

Le filtre DLS est une Query DSL OpenSearch appliquée silencieusement à chaque requête de l'utilisateur. C'est transparent pour le client — l'analyst croit rechercher dans tous les produits, mais le Security Plugin ajoute automatiquement le filtre `term: {category: "Électronique"}` à chaque requête.

**Exemple de requête analyst (ce qu'il envoie) :**
```json
{ "query": { "match": { "name": "laptop" } } }
```

**Requête réellement exécutée par OpenSearch :**
```json
{
  "query": {
    "bool": {
      "must":   [{ "match": { "name": "laptop" } }],
      "filter": [{ "term": { "category": "Électronique" } }]
    }
  }
}
```

### Test DLS

```bash
# Compter tous les produits via analyst (doit ne voir que Électronique)
curl -X GET "https://localhost:9200/products/_count" \
  -k -u analyst:Analyst@Pass2026! \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} } }'

# Comparer avec admin (voit tous les produits)
curl -X GET "https://localhost:9200/products/_count" \
  -k -u admin:Formation@OpenSearch2024! \
  -H "Content-Type: application/json" \
  -d '{ "query": { "match_all": {} } }'
```

**Résultat :** Le count de l'analyst est inférieur au count de l'admin — démontrant que le DLS fonctionne correctement.

---

## Résumé des concepts de sécurité

| Concept      | Description                                                              |
|--------------|--------------------------------------------------------------------------|
| TLS Transport| Chiffrement des communications inter-nœuds (port 9300)                   |
| TLS REST     | Chiffrement des communications client → cluster (port 9200, HTTPS)       |
| Internal users| Utilisateurs stockés dans l'index `.opendistro_security`                |
| Backend roles| Rôles provenant d'un annuaire LDAP/Active Directory externe              |
| Roles        | Ensemble de permissions (cluster + index + tenant)                        |
| Role mapping | Association entre utilisateurs/backend_roles et rôles OpenSearch          |
| DLS          | Filtre au niveau document — restreint les documents visibles              |
| FLS          | Filtre au niveau champ — masque certains champs dans les résultats        |
| Audit log    | Traçabilité des actions (connexions, recherches, modifications)            |
| Tenant       | Espace de travail isolé dans Dashboards (tableaux de bord séparés)       |
