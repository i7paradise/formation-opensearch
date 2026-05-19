#!/bin/bash

# =============================================================================
# seed-data-with-security.sh — Chargement des données de démonstration (TP5)
# Auteur : Kit de formation OpenSearch 3.6
# Usage  : ./seed-data-with-security.sh
# Prérequis : stack docker-compose.security.yml démarré
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_DIR="${PROJECT_DIR}/data"
COMPOSE_FILE="${PROJECT_DIR}/infrastructure/docker-compose.security.yml"

# -----------------------------------------------------------------------------
# Lecture du mot de passe admin depuis docker-compose.security.yml
# -----------------------------------------------------------------------------
if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "[ERREUR] Fichier introuvable : ${COMPOSE_FILE}" >&2
  exit 1
fi

ADMIN_PASSWORD=$(grep "OPENSEARCH_INITIAL_ADMIN_PASSWORD" "${COMPOSE_FILE}" \
  | head -1 | sed 's/.*=//; s/[[:space:]]*//')

if [[ -z "${ADMIN_PASSWORD}" ]]; then
  echo "[ERREUR] Impossible de lire OPENSEARCH_INITIAL_ADMIN_PASSWORD dans ${COMPOSE_FILE}" >&2
  exit 1
fi

BASE_URL="https://localhost:9200"
CURL_OPTS="-k -u admin:${ADMIN_PASSWORD}"

# -----------------------------------------------------------------------------
# Couleurs pour l'affichage console
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[AVERT]${NC} $*"; }
log_error()   { echo -e "${RED}[ERREUR]${NC} $*"; }
log_step()    { echo -e "\n${BOLD}${CYAN}==> $*${NC}"; }

# -----------------------------------------------------------------------------
# Étape 1 : Attente que OpenSearch soit disponible
# -----------------------------------------------------------------------------
log_step "Attente de la disponibilité d'OpenSearch..."
log_info "Connexion : admin@${BASE_URL} (mot de passe depuis docker-compose.security.yml)"

MAX_RETRIES=60
RETRY_COUNT=0

while true; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 \
    ${CURL_OPTS} "${BASE_URL}/_cluster/health" 2>/dev/null || echo "000")

  if [[ "${HTTP_CODE}" == "200" ]]; then
    log_success "OpenSearch disponible sur ${BASE_URL}"
    break
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [[ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]]; then
    log_error "OpenSearch n'est pas disponible après ${MAX_RETRIES} tentatives."
    log_error "Vérifiez que le conteneur est démarré : docker ps"
    log_error "Consultez les logs : docker logs opensearch-security"
    exit 1
  fi

  log_info "Tentative ${RETRY_COUNT}/${MAX_RETRIES} — OpenSearch pas encore prêt (code HTTP : ${HTTP_CODE})..."
  sleep 2
done

# -----------------------------------------------------------------------------
# Étape 2 : Création des indices avec mappings explicites
# -----------------------------------------------------------------------------
log_step "Création des indices avec leurs mappings..."

# --- Index : products ---
log_info "Création de l'index 'products'..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT ${CURL_OPTS} "${BASE_URL}/products" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "analysis": {
        "analyzer": {
          "french_analyzer": {
            "type": "standard",
            "stopwords": "_french_"
          }
        }
      }
    },
    "mappings": {
      "properties": {
        "name": {
          "type": "text",
          "analyzer": "french_analyzer",
          "fields": {
            "keyword": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "description": {
          "type": "text",
          "analyzer": "french_analyzer"
        },
        "category":      { "type": "keyword" },
        "sub_category":  { "type": "keyword" },
        "brand": {
          "type": "keyword",
          "fields": {
            "text": { "type": "text" }
          }
        },
        "price":          { "type": "float" },
        "original_price": { "type": "float" },
        "currency":       { "type": "keyword" },
        "in_stock":       { "type": "boolean" },
        "stock_quantity": { "type": "integer" },
        "rating":         { "type": "float" },
        "reviews_count":  { "type": "integer" },
        "tags":           { "type": "keyword" },
        "created_at":     { "type": "date" },
        "updated_at":     { "type": "date" },
        "seller": {
          "type": "keyword",
          "fields": {
            "text": { "type": "text" }
          }
        },
        "weight_kg": { "type": "float" },
        "color":     { "type": "keyword" }
      }
    }
  }')

if [[ "${RESPONSE}" == "200" ]] || [[ "${RESPONSE}" == "201" ]]; then
  log_success "Index 'products' créé"
else
  log_warn "Index 'products' : réponse HTTP ${RESPONSE} (peut déjà exister)"
fi

# --- Index : stores ---
log_info "Création de l'index 'stores'..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT ${CURL_OPTS} "${BASE_URL}/stores" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "name": {
          "type": "text",
          "fields": {
            "keyword": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "city":           { "type": "keyword" },
        "address":        { "type": "text" },
        "location":       { "type": "geo_point" },
        "type":           { "type": "keyword" },
        "opening_hours":  { "type": "keyword" },
        "categories":     { "type": "keyword" },
        "employee_count": { "type": "integer" }
      }
    }
  }')

if [[ "${RESPONSE}" == "200" ]] || [[ "${RESPONSE}" == "201" ]]; then
  log_success "Index 'stores' créé"
else
  log_warn "Index 'stores' : réponse HTTP ${RESPONSE} (peut déjà exister)"
fi

# --- Index : logs ---
log_info "Création de l'index 'logs'..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT ${CURL_OPTS} "${BASE_URL}/logs" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "timestamp":        { "type": "date" },
        "level":            { "type": "keyword" },
        "service":          { "type": "keyword" },
        "message":          { "type": "text" },
        "http_status":      { "type": "integer" },
        "response_time_ms": { "type": "integer" },
        "user_id":          { "type": "keyword" },
        "trace_id":         { "type": "keyword" }
      }
    }
  }')

if [[ "${RESPONSE}" == "200" ]] || [[ "${RESPONSE}" == "201" ]]; then
  log_success "Index 'logs' créé"
else
  log_warn "Index 'logs' : réponse HTTP ${RESPONSE} (peut déjà exister)"
fi

# -----------------------------------------------------------------------------
# Étape 3 : Chargement des données via l'API Bulk
# -----------------------------------------------------------------------------
log_step "Chargement des données de démonstration..."

# --- Produits : chargement via l'API Bulk (fichier NDJSON) ---
PRODUCTS_BULK="${DATA_DIR}/products-bulk.ndjson"
if [[ -f "${PRODUCTS_BULK}" ]]; then
  log_info "Chargement des produits depuis ${PRODUCTS_BULK}..."
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST ${CURL_OPTS} "${BASE_URL}/_bulk" \
    -H "Content-Type: application/x-ndjson" \
    --data-binary "@${PRODUCTS_BULK}")
  if [[ "${RESPONSE}" == "200" ]]; then
    log_success "Produits chargés via API Bulk"
  else
    log_warn "Chargement produits Bulk : réponse HTTP ${RESPONSE}"
  fi
else
  log_warn "Fichier products-bulk.ndjson introuvable : ${PRODUCTS_BULK}"
  log_info "Chargement de produits de démonstration intégrés..."

  curl -s -o /dev/null -X POST ${CURL_OPTS} "${BASE_URL}/_bulk" \
    -H "Content-Type: application/x-ndjson" \
    -d '{"index":{"_index":"products","_id":"1"}}
{"name":"Laptop ProBook 15","description":"Ordinateur portable professionnel 15 pouces, Intel Core i7, 16 Go RAM","category":"Informatique","sub_category":"Ordinateurs portables","brand":"TechPro","price":899.99,"original_price":1099.99,"currency":"EUR","in_stock":true,"stock_quantity":45,"rating":4.5,"reviews_count":128,"tags":["laptop","professionnel","intel"],"created_at":"2024-01-15T10:00:00Z","updated_at":"2024-03-20T14:30:00Z","seller":"TechStore Paris","weight_kg":1.8,"color":"Argent"}
{"index":{"_index":"products","_id":"2"}}
{"name":"Smartphone Galaxy S25","description":"Smartphone haut de gamme 6.7 pouces, 256 Go, 5G","category":"Téléphonie","sub_category":"Smartphones","brand":"Samsung","price":1199.00,"original_price":1199.00,"currency":"EUR","in_stock":true,"stock_quantity":120,"rating":4.7,"reviews_count":342,"tags":["smartphone","5g","android","samsung"],"created_at":"2024-02-01T08:00:00Z","updated_at":"2024-04-01T09:00:00Z","seller":"ElectroShop","weight_kg":0.19,"color":"Noir"}
{"index":{"_index":"products","_id":"3"}}
{"name":"Casque Audio Premium","description":"Casque sans fil à réduction de bruit active, autonomie 30h","category":"Audio","sub_category":"Casques","brand":"SoundMax","price":249.99,"original_price":299.99,"currency":"EUR","in_stock":false,"stock_quantity":0,"rating":4.3,"reviews_count":87,"tags":["casque","audio","bluetooth","anc"],"created_at":"2024-01-20T12:00:00Z","updated_at":"2024-03-15T16:00:00Z","seller":"AudioZone","weight_kg":0.28,"color":"Blanc"}
{"index":{"_index":"products","_id":"4"}}
{"name":"Tablette iPad Air","description":"Tablette Apple 10.9 pouces, M2, 256 Go WiFi","category":"Informatique","sub_category":"Tablettes","brand":"Apple","price":799.00,"original_price":799.00,"currency":"EUR","in_stock":true,"stock_quantity":63,"rating":4.8,"reviews_count":215,"tags":["tablette","apple","ipad","m2"],"created_at":"2024-03-01T10:00:00Z","updated_at":"2024-04-10T11:00:00Z","seller":"iStore","weight_kg":0.46,"color":"Bleu"}
{"index":{"_index":"products","_id":"5"}}
{"name":"Montre Connectée FitPro","description":"Montre sport connectée GPS, suivi santé, étanche 50m","category":"Wearables","sub_category":"Montres connectées","brand":"FitBand","price":179.99,"original_price":219.99,"currency":"EUR","in_stock":true,"stock_quantity":89,"rating":4.1,"reviews_count":156,"tags":["montre","sport","gps","sante"],"created_at":"2024-02-15T09:00:00Z","updated_at":"2024-04-05T13:00:00Z","seller":"SportTech","weight_kg":0.045,"color":"Rouge"}
'
  log_success "Produits de démonstration intégrés chargés"
fi

# --- Magasins : chargement individuel depuis stores.json ---
STORES_FILE="${DATA_DIR}/stores.json"
if [[ -f "${STORES_FILE}" ]]; then
  log_info "Chargement des magasins depuis ${STORES_FILE}..."

  if command -v jq &>/dev/null; then
    log_info "Chargement des magasins via jq + Bulk API..."
    jq -c '.[] | [{"index":{"_index":"stores","_id":(.id|tostring)}}, .] | .[]' "${STORES_FILE}" | \
      curl -s -o /dev/null -X POST ${CURL_OPTS} "${BASE_URL}/_bulk" \
        -H "Content-Type: application/x-ndjson" \
        --data-binary @-
    log_success "Magasins chargés"
  else
    log_warn "jq non disponible — chargement de magasins de démonstration intégrés..."
    curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/stores/_doc/1" \
      -H "Content-Type: application/json" \
      -d '{"name":"TechStore Paris Centre","city":"Paris","address":"15 rue de Rivoli, 75001 Paris","location":{"lat":48.8566,"lon":2.3522},"type":"Flagship","opening_hours":"9h-20h","categories":["Informatique","Téléphonie","Audio"],"employee_count":45}'
    curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/stores/_doc/2" \
      -H "Content-Type: application/json" \
      -d '{"name":"ElectroShop Lyon","city":"Lyon","address":"8 place Bellecour, 69002 Lyon","location":{"lat":45.7578,"lon":4.8320},"type":"Standard","opening_hours":"10h-19h","categories":["Téléphonie","Wearables"],"employee_count":22}'
    curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/stores/_doc/3" \
      -H "Content-Type: application/json" \
      -d '{"name":"AudioZone Marseille","city":"Marseille","address":"42 la Canebière, 13001 Marseille","location":{"lat":43.2965,"lon":5.3698},"type":"Spécialisé","opening_hours":"10h-19h30","categories":["Audio"],"employee_count":12}'
    log_success "Magasins de démonstration intégrés chargés"
  fi
else
  log_warn "Fichier stores.json introuvable : ${STORES_FILE}"
  log_info "Chargement de magasins de démonstration intégrés..."
  curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/stores/_doc/1" \
    -H "Content-Type: application/json" \
    -d '{"name":"TechStore Paris Centre","city":"Paris","address":"15 rue de Rivoli, 75001 Paris","location":{"lat":48.8566,"lon":2.3522},"type":"Flagship","opening_hours":"9h-20h","categories":["Informatique","Téléphonie","Audio"],"employee_count":45}'
  curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/stores/_doc/2" \
    -H "Content-Type: application/json" \
    -d '{"name":"ElectroShop Lyon","city":"Lyon","address":"8 place Bellecour, 69002 Lyon","location":{"lat":45.7578,"lon":4.8320},"type":"Standard","opening_hours":"10h-19h","categories":["Téléphonie","Wearables"],"employee_count":22}'
  curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/stores/_doc/3" \
    -H "Content-Type: application/json" \
    -d '{"name":"AudioZone Marseille","city":"Marseille","address":"42 la Canebière, 13001 Marseille","location":{"lat":43.2965,"lon":5.3698},"type":"Spécialisé","opening_hours":"10h-19h30","categories":["Audio"],"employee_count":12}'
  log_success "Magasins de démonstration intégrés chargés"
fi

# --- Logs : chargement individuel depuis logs-sample.json ---
LOGS_FILE="${DATA_DIR}/logs-sample.json"
if [[ -f "${LOGS_FILE}" ]]; then
  log_info "Chargement des logs depuis ${LOGS_FILE}..."
  if command -v jq &>/dev/null; then
    log_info "Chargement des logs via jq + Bulk API..."
    jq -c 'to_entries[] | [{"index":{"_index":"logs","_id":((.key+1)|tostring)}}, .value] | .[]' "${LOGS_FILE}" | \
      curl -s -o /dev/null -X POST ${CURL_OPTS} "${BASE_URL}/_bulk" \
        -H "Content-Type: application/x-ndjson" \
        --data-binary @-
    log_success "Logs chargés"
  else
    log_warn "jq non disponible — logs ignorés"
  fi
else
  log_warn "Fichier logs-sample.json introuvable : ${LOGS_FILE}"
  log_info "Chargement de logs de démonstration intégrés..."

  TIMESTAMP_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  for i in 1 2 3 4 5; do
    STATUS_CODES=(200 200 200 404 500)
    LEVELS=(INFO INFO INFO WARN ERROR)
    SERVICES=(api-gateway product-service user-service product-service payment-service)
    MESSAGES=("Requête GET /api/products traitée" "Produit ID-42 récupéré" "Utilisateur user-789 authentifié" "Produit ID-999 non trouvé" "Erreur de connexion à la base de données")
    IDX=$((i - 1))
    curl -s -o /dev/null -X PUT ${CURL_OPTS} "${BASE_URL}/logs/_doc/${i}" \
      -H "Content-Type: application/json" \
      -d "{\"timestamp\":\"${TIMESTAMP_NOW}\",\"level\":\"${LEVELS[${IDX}]}\",\"service\":\"${SERVICES[${IDX}]}\",\"message\":\"${MESSAGES[${IDX}]}\",\"http_status\":${STATUS_CODES[${IDX}]},\"response_time_ms\":$((RANDOM % 500 + 10)),\"user_id\":\"user-${i}\",\"trace_id\":\"trace-$(date +%s)-${i}\"}"
  done
  log_success "Logs de démonstration intégrés chargés"
fi

# -----------------------------------------------------------------------------
# Étape 4 : Rafraîchissement des indices
# -----------------------------------------------------------------------------
log_info "Rafraîchissement des indices pour rendre les documents visibles..."
curl -s -o /dev/null -X POST ${CURL_OPTS} "${BASE_URL}/products,stores,logs/_refresh"
sleep 1

# -----------------------------------------------------------------------------
# Étape 5 : Vérification du nombre de documents
# -----------------------------------------------------------------------------
log_step "Vérification des données indexées..."

sleep 2

CAT_RESPONSE=$(curl -s ${CURL_OPTS} "${BASE_URL}/_cat/indices?v&h=index,docs.count,store.size,health" 2>/dev/null || echo "")

# -----------------------------------------------------------------------------
# Étape 6 : Affichage du tableau récapitulatif
# -----------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}  Récapitulatif du chargement des données${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"

for INDEX in products stores logs; do
  COUNT=$(curl -s ${CURL_OPTS} "${BASE_URL}/${INDEX}/_count" 2>/dev/null | grep -oE '"count":[0-9]+' | grep -oE '[0-9]+' || echo "0")
  printf "  %-20s : %s documents\n" "${INDEX}" "${COUNT}"
done

echo ""
echo -e "${BOLD}Vue détaillée (_cat/indices) :${NC}"
if [[ -n "${CAT_RESPONSE}" ]]; then
  echo "${CAT_RESPONSE}" | grep -E "^(index|products|stores|logs)" || echo "${CAT_RESPONSE}"
else
  log_warn "Impossible de récupérer les statistiques des indices"
fi

echo ""
log_success "Chargement des données terminé !"
echo -e "  Accédez aux données : ${CYAN}${BASE_URL}/_cat/indices?v${NC}"
echo -e "  Exemple de requête  : ${CYAN}curl -k -u admin:${ADMIN_PASSWORD} ${BASE_URL}/products/_search?pretty${NC}"
