#!/bin/bash

# =============================================================================
# setup.sh — Script d'initialisation de l'environnement de formation OpenSearch
# Auteur : Kit de formation OpenSearch 3.6
# Usage  : ./setup.sh
# =============================================================================

set -euo pipefail

# URL de base de l'API OpenSearch
BASE_URL="http://localhost:9200"

# Répertoire racine du projet (répertoire parent de scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${PROJECT_DIR}/infrastructure"

# -----------------------------------------------------------------------------
# Couleurs pour l'affichage console
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Pas de couleur (reset)

# -----------------------------------------------------------------------------
# Fonctions utilitaires d'affichage
# -----------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[AVERT]${NC} $*"; }
log_error()   { echo -e "${RED}[ERREUR]${NC} $*"; }
log_step()    { echo -e "\n${BOLD}${CYAN}==> $*${NC}"; }
log_banner()  {
  echo -e "${BOLD}${BLUE}"
  echo "============================================================"
  echo " $*"
  echo "============================================================"
  echo -e "${NC}"
}

# -----------------------------------------------------------------------------
# Étape 1 : Vérification des prérequis
# -----------------------------------------------------------------------------
log_banner "Kit de formation OpenSearch 3.6 — Initialisation"
log_step "Vérification des prérequis..."

# --- Vérification de Docker ---
log_info "Vérification de l'installation de Docker..."
if ! command -v docker &>/dev/null; then
  log_error "Docker n'est pas installé. Installez Docker Desktop depuis https://docker.com"
  exit 1
fi
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
log_success "Docker installé (version ${DOCKER_VERSION})"

# --- Vérification que Docker est en cours d'exécution ---
log_info "Vérification que le démon Docker est actif..."
if ! docker info &>/dev/null; then
  log_error "Le démon Docker n'est pas démarré. Lancez Docker Desktop et réessayez."
  exit 1
fi
log_success "Démon Docker actif"

# --- Vérification de docker-compose ---
log_info "Vérification de docker-compose..."
if command -v docker-compose &>/dev/null; then
  COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  COMPOSE_CMD="docker-compose"
  log_success "docker-compose disponible (version ${COMPOSE_VERSION})"
elif docker compose version &>/dev/null 2>&1; then
  COMPOSE_VERSION=$(docker compose version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  COMPOSE_CMD="docker compose"
  log_success "docker compose (plugin) disponible (version ${COMPOSE_VERSION})"
else
  log_error "docker-compose n'est pas disponible. Installez le plugin Compose pour Docker."
  exit 1
fi

# --- Vérification de la mémoire disponible ---
log_info "Vérification de la mémoire disponible..."
PLATFORM="$(uname -s)"

if [[ "${PLATFORM}" == "Linux" ]]; then
  # Sur Linux : lire la mémoire totale depuis /proc/meminfo
  TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  TOTAL_MEM_GB=$(echo "scale=1; ${TOTAL_MEM_KB} / 1048576" | bc)
  AVAIL_MEM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
  AVAIL_MEM_GB=$(echo "scale=1; ${AVAIL_MEM_KB} / 1048576" | bc)
elif [[ "${PLATFORM}" == "Darwin" ]]; then
  # Sur macOS : utiliser sysctl
  TOTAL_MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  TOTAL_MEM_GB=$(echo "scale=1; ${TOTAL_MEM_BYTES} / 1073741824" | bc)
  # Sur Mac avec Docker Desktop, la mémoire allouée est limitée par les paramètres Docker
  AVAIL_MEM_GB="${TOTAL_MEM_GB}"
else
  TOTAL_MEM_GB="inconnu"
  AVAIL_MEM_GB="inconnu"
fi

if [[ "${AVAIL_MEM_GB}" != "inconnu" ]]; then
  AVAIL_INT=$(echo "${AVAIL_MEM_GB}" | cut -d. -f1)
  if [[ ${AVAIL_INT} -lt 4 ]]; then
    log_warn "Mémoire disponible (${AVAIL_MEM_GB} Go) inférieure à 4 Go recommandés."
    log_warn "La formation peut fonctionner mais des ralentissements sont possibles."
    log_warn "Sur Docker Desktop (Mac/Windows) : augmentez la RAM dans Préférences > Ressources."
  else
    log_success "Mémoire disponible : ${AVAIL_MEM_GB} Go (minimum recommandé : 4 Go)"
  fi
fi

# --- Vérification et configuration de vm.max_map_count ---
log_info "Vérification de vm.max_map_count (requis par OpenSearch)..."
REQUIRED_MAP_COUNT=262144

if [[ "${PLATFORM}" == "Linux" ]]; then
  CURRENT_MAP_COUNT=$(cat /proc/sys/vm/max_map_count 2>/dev/null || echo 0)
  if [[ ${CURRENT_MAP_COUNT} -lt ${REQUIRED_MAP_COUNT} ]]; then
    log_warn "vm.max_map_count actuel (${CURRENT_MAP_COUNT}) < ${REQUIRED_MAP_COUNT} requis."
    log_info "Tentative de configuration automatique (nécessite sudo)..."
    if sudo sysctl -w vm.max_map_count=${REQUIRED_MAP_COUNT} &>/dev/null; then
      log_success "vm.max_map_count configuré à ${REQUIRED_MAP_COUNT}"
      log_warn "Pour rendre ce paramètre permanent, ajoutez à /etc/sysctl.conf :"
      log_warn "  vm.max_map_count=${REQUIRED_MAP_COUNT}"
    else
      log_error "Impossible de configurer vm.max_map_count. Exécutez manuellement :"
      log_error "  sudo sysctl -w vm.max_map_count=${REQUIRED_MAP_COUNT}"
      exit 1
    fi
  else
    log_success "vm.max_map_count = ${CURRENT_MAP_COUNT} (OK)"
  fi
elif [[ "${PLATFORM}" == "Darwin" ]]; then
  # Sur macOS avec Docker Desktop, vm.max_map_count n'est pas accessible directement
  # Docker Desktop gère sa propre VM Linux interne
  log_warn "macOS détecté : vm.max_map_count géré par Docker Desktop automatiquement."
  log_warn "Si OpenSearch échoue au démarrage, augmentez la RAM dans Docker Desktop > Ressources."
fi

log_success "Tous les prérequis sont satisfaits !"

# -----------------------------------------------------------------------------
# Étape 2 : Démarrage de l'environnement Docker
# -----------------------------------------------------------------------------
log_step "Démarrage de l'environnement Docker..."

# Vérifier que le répertoire infrastructure existe
if [[ ! -d "${INFRA_DIR}" ]]; then
  log_error "Répertoire infrastructure introuvable : ${INFRA_DIR}"
  exit 1
fi

if [[ ! -f "${INFRA_DIR}/docker-compose.yml" ]]; then
  log_error "Fichier docker-compose.yml introuvable dans : ${INFRA_DIR}"
  exit 1
fi

log_info "Lancement des conteneurs Docker (détaché)..."
if ! (cd "${INFRA_DIR}" && ${COMPOSE_CMD} up -d); then
  log_error "Échec du démarrage des conteneurs Docker."
  log_error "Vérifiez les logs avec : ${COMPOSE_CMD} -f ${INFRA_DIR}/docker-compose.yml logs"
  exit 1
fi
log_success "Conteneurs Docker démarrés"

# -----------------------------------------------------------------------------
# Étape 3 : Attente que le cluster soit prêt (état "green")
# -----------------------------------------------------------------------------
log_step "Attente que le cluster OpenSearch soit opérationnel..."

TIMEOUT=120    # Timeout total en secondes
RETRY_INTERVAL=5  # Intervalle entre les tentatives
ELAPSED=0

log_info "Interrogation de ${BASE_URL}/_cluster/health (timeout : ${TIMEOUT}s)..."

while true; do
  # Tenter d'obtenir l'état du cluster
  HEALTH_RESPONSE=$(curl -s --connect-timeout 3 "${BASE_URL}/_cluster/health" 2>/dev/null || echo "")

  if [[ -n "${HEALTH_RESPONSE}" ]]; then
    CLUSTER_STATUS=$(echo "${HEALTH_RESPONSE}" | grep -oE '"status":"[^"]*"' | cut -d'"' -f4 || echo "")

    if [[ "${CLUSTER_STATUS}" == "green" ]]; then
      log_success "Cluster OpenSearch en état GREEN !"
      break
    elif [[ "${CLUSTER_STATUS}" == "yellow" ]]; then
      log_warn "Cluster en état YELLOW (normal pour un noeud unique). Poursuite..."
      break
    else
      log_info "Cluster en cours de démarrage... (état : ${CLUSTER_STATUS:-inconnu}, ${ELAPSED}s écoulées)"
    fi
  else
    log_info "OpenSearch pas encore disponible... (${ELAPSED}s écoulées)"
  fi

  # Vérifier le timeout
  if [[ ${ELAPSED} -ge ${TIMEOUT} ]]; then
    log_error "Timeout atteint (${TIMEOUT}s). OpenSearch ne répond pas."
    log_error "Vérifiez les logs : docker logs opensearch"
    exit 1
  fi

  sleep ${RETRY_INTERVAL}
  ELAPSED=$((ELAPSED + RETRY_INTERVAL))
done

# -----------------------------------------------------------------------------
# Étape 4 : Chargement des données de démonstration
# -----------------------------------------------------------------------------
log_step "Chargement des données de démonstration..."

SEED_SCRIPT="${SCRIPT_DIR}/seed-data.sh"

if [[ ! -f "${SEED_SCRIPT}" ]]; then
  log_warn "Script seed-data.sh introuvable : ${SEED_SCRIPT}"
  log_warn "Les données de démonstration ne seront pas chargées."
else
  log_info "Exécution de seed-data.sh..."
  if bash "${SEED_SCRIPT}"; then
    log_success "Données de démonstration chargées avec succès !"
  else
    log_warn "Le chargement des données a rencontré des erreurs (non bloquant)."
    log_warn "Relancez manuellement : bash ${SEED_SCRIPT}"
  fi
fi

# -----------------------------------------------------------------------------
# Étape 5 : Message de succès et URLs d'accès
# -----------------------------------------------------------------------------
log_banner "Environnement de formation prêt !"

echo -e "${GREEN}${BOLD}Accès aux services :${NC}"
echo -e "  ${CYAN}API OpenSearch${NC}     : ${BASE_URL}"
echo -e "  ${CYAN}Cluster Health${NC}     : ${BASE_URL}/_cluster/health?pretty"
echo -e "  ${CYAN}Indices${NC}            : ${BASE_URL}/_cat/indices?v"
echo -e "  ${CYAN}Dashboards${NC}         : http://localhost:5601"
echo ""
echo -e "${GREEN}${BOLD}Commandes utiles :${NC}"
echo -e "  Santé du cluster   : bash ${SCRIPT_DIR}/check-health.sh"
echo -e "  Réinitialisation   : bash ${SCRIPT_DIR}/reset.sh"
echo -e "  Arrêt des services : (cd ${INFRA_DIR} && ${COMPOSE_CMD} down)"
echo -e "  Arrêt + volumes    : (cd ${INFRA_DIR} && ${COMPOSE_CMD} down -v)"
echo ""
echo -e "${YELLOW}Bonne formation OpenSearch !${NC}"
