#!/bin/bash

# =============================================================================
# check-health.sh — Diagnostic de l'état du cluster OpenSearch
# Auteur : Kit de formation OpenSearch 3.6
# Usage  : ./check-health.sh
# =============================================================================

set -euo pipefail

# URL de base de l'API OpenSearch
BASE_URL="http://localhost:9200"

# Nom du conteneur Docker OpenSearch (noeud unique)
CONTAINER_NAME="opensearch"

# -----------------------------------------------------------------------------
# Couleurs pour l'affichage console
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log_section() {
  echo ""
  echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $*${NC}"
  echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[AVERT]${NC} $*"; }
log_error()   { echo -e "${RED}[ERREUR]${NC} $*"; }

# Fonction pour afficher une valeur avec couleur selon le statut
color_status() {
  local STATUS="$1"
  case "${STATUS}" in
    green)  echo -e "${GREEN}${STATUS}${NC}" ;;
    yellow) echo -e "${YELLOW}${STATUS}${NC}" ;;
    red)    echo -e "${RED}${STATUS}${NC}" ;;
    *)      echo -e "${BLUE}${STATUS}${NC}" ;;
  esac
}

# Timestamp du rapport
REPORT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# En-tête du rapport
echo -e "${BOLD}${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Rapport de santé OpenSearch — Formation                ║"
echo "║       ${REPORT_TIME}                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérification de la disponibilité d'OpenSearch
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE_URL}/_cluster/health" 2>/dev/null || echo "000")
if [[ "${HTTP_CODE}" != "200" ]]; then
  echo -e "${RED}${BOLD}OpenSearch n'est pas accessible (code HTTP : ${HTTP_CODE})${NC}"
  echo ""
  echo "Solutions possibles :"
  echo "  1. Vérifiez que le conteneur est démarré : docker ps"
  echo "  2. Lancez l'environnement : bash $(dirname "${BASH_SOURCE[0]}")/setup.sh"
  echo "  3. Consultez les logs : docker logs ${CONTAINER_NAME}"
  exit 1
fi

# =============================================================================
# Section 1 : Santé du cluster
# =============================================================================
log_section "1. Santé du cluster"

HEALTH_JSON=$(curl -s "${BASE_URL}/_cluster/health?pretty" 2>/dev/null || echo "{}")

# Extraction des informations clés
CLUSTER_NAME=$(echo "${HEALTH_JSON}" | grep -oE '"cluster_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "inconnu")
CLUSTER_STATUS=$(echo "${HEALTH_JSON}" | grep -oE '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 || echo "inconnu")
NUM_NODES=$(echo "${HEALTH_JSON}" | grep -oE '"number_of_nodes"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' || echo "0")
NUM_DATA_NODES=$(echo "${HEALTH_JSON}" | grep -oE '"number_of_data_nodes"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' || echo "0")
ACTIVE_SHARDS=$(echo "${HEALTH_JSON}" | grep -oE '"active_shards"[[:space:]]*:[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+' || echo "0")
ACTIVE_PRIMARY=$(echo "${HEALTH_JSON}" | grep -oE '"active_primary_shards"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' || echo "0")
UNASSIGNED_SHARDS=$(echo "${HEALTH_JSON}" | grep -oE '"unassigned_shards"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' || echo "0")
PENDING_TASKS=$(echo "${HEALTH_JSON}" | grep -oE '"number_of_pending_tasks"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' || echo "0")

echo ""
printf "  %-30s : " "Cluster"
echo -e "${BOLD}${CLUSTER_NAME}${NC}"

printf "  %-30s : " "Statut"
color_status "${CLUSTER_STATUS}"

printf "  %-30s : %s\n" "Nombre de noeuds" "${NUM_NODES}"
printf "  %-30s : %s\n" "Noeuds de données" "${NUM_DATA_NODES}"
printf "  %-30s : %s\n" "Shards actifs (total)" "${ACTIVE_SHARDS}"
printf "  %-30s : %s\n" "Shards primaires actifs" "${ACTIVE_PRIMARY}"

if [[ "${UNASSIGNED_SHARDS}" -gt 0 ]]; then
  printf "  %-30s : " "Shards non assignés"
  echo -e "${YELLOW}${UNASSIGNED_SHARDS}${NC}"
else
  printf "  %-30s : %s\n" "Shards non assignés" "0"
fi

if [[ "${PENDING_TASKS}" -gt 0 ]]; then
  printf "  %-30s : " "Tâches en attente"
  echo -e "${YELLOW}${PENDING_TASKS}${NC}"
else
  printf "  %-30s : %s\n" "Tâches en attente" "0"
fi

# Interprétation du statut
echo ""
case "${CLUSTER_STATUS}" in
  green)
    log_success "Cluster en parfait état — tous les shards sont assignés et répliqués"
    ;;
  yellow)
    log_warn "Cluster fonctionnel — shards primaires OK, mais des réplicas ne sont pas assignés"
    log_warn "(Normal pour un noeud unique sans réplicas)"
    ;;
  red)
    log_error "Cluster en état critique — certains shards primaires ne sont pas assignés !"
    ;;
esac

# =============================================================================
# Section 2 : Liste des noeuds
# =============================================================================
log_section "2. Noeuds du cluster"

echo ""
NODES_RESPONSE=$(curl -s "${BASE_URL}/_cat/nodes?v&h=name,ip,heapPercent,heapMax,ramPercent,ramMax,cpu,load_1m,nodeRole,master,version" 2>/dev/null || echo "Erreur de connexion")

if [[ -n "${NODES_RESPONSE}" ]] && [[ "${NODES_RESPONSE}" != "Erreur"* ]]; then
  # Colorer la ligne d'en-tête
  echo -e "${BOLD}${NODES_RESPONSE}${NC}" | head -1
  echo "${NODES_RESPONSE}" | tail -n +2 | while IFS= read -r line; do
    # Marquer le noeud master en vert
    if echo "${line}" | grep -q "\*"; then
      echo -e "${GREEN}${line}${NC}"
    else
      echo "${line}"
    fi
  done
else
  log_warn "Impossible de récupérer la liste des noeuds"
fi

# =============================================================================
# Section 3 : Liste des indices
# =============================================================================
log_section "3. Indices et données"

echo ""
INDICES_RESPONSE=$(curl -s "${BASE_URL}/_cat/indices?v&s=index&h=health,status,index,pri,rep,docs.count,docs.deleted,store.size,pri.store.size" 2>/dev/null || echo "Erreur de connexion")

if [[ -n "${INDICES_RESPONSE}" ]] && [[ "${INDICES_RESPONSE}" != "Erreur"* ]]; then
  echo "${INDICES_RESPONSE}" | while IFS= read -r line; do
    if echo "${line}" | grep -q "^health" || echo "${line}" | grep -q "^index"; then
      # En-tête
      echo -e "${BOLD}${line}${NC}"
    elif echo "${line}" | grep -q "^green"; then
      echo -e "${GREEN}${line}${NC}"
    elif echo "${line}" | grep -q "^yellow"; then
      echo -e "${YELLOW}${line}${NC}"
    elif echo "${line}" | grep -q "^red"; then
      echo -e "${RED}${line}${NC}"
    else
      echo "${line}"
    fi
  done
else
  log_warn "Impossible de récupérer la liste des indices"
fi

# Afficher le nombre total de documents
echo ""
TOTAL_DOCS=$(curl -s "${BASE_URL}/_cat/count?h=count" 2>/dev/null | tr -d '[:space:]' || echo "inconnu")
echo -e "  ${BOLD}Total de documents dans le cluster : ${CYAN}${TOTAL_DOCS}${NC}"

# =============================================================================
# Section 4 : Logs récents du conteneur Docker
# =============================================================================
log_section "4. Logs récents du conteneur Docker (20 dernières lignes)"

echo ""

# Vérifier si Docker est disponible et si le conteneur existe
if command -v docker &>/dev/null; then
  if docker inspect "${CONTAINER_NAME}" &>/dev/null 2>&1; then
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "inconnu")
    echo -e "  Statut du conteneur '${CONTAINER_NAME}' : $(color_status "${CONTAINER_STATUS}")"
    echo ""
    echo -e "${BOLD}Dernières lignes de logs (stderr inclus) :${NC}"
    echo "────────────────────────────────────────────────────────────"
    docker logs "${CONTAINER_NAME}" 2>&1 | tail -20 | while IFS= read -r line; do
      # Colorer les lignes selon le niveau de log
      if echo "${line}" | grep -qiE "ERROR|FATAL|CRITICAL"; then
        echo -e "${RED}${line}${NC}"
      elif echo "${line}" | grep -qiE "WARN|WARNING"; then
        echo -e "${YELLOW}${line}${NC}"
      else
        echo "${line}"
      fi
    done
    echo "────────────────────────────────────────────────────────────"
  else
    log_warn "Conteneur '${CONTAINER_NAME}' introuvable."
    log_info "En mode cluster, les conteneurs s'appellent : opensearch-node1, opensearch-node2, opensearch-node3"
    log_info "Pour voir les logs d'un noeud de cluster : docker logs opensearch-node1 2>&1 | tail -20"
  fi
else
  log_warn "Docker non disponible — logs du conteneur ignorés"
fi

# =============================================================================
# Section 5 : Informations sur les ressources (facultatif)
# =============================================================================
log_section "5. Statistiques des noeuds"

echo ""
STATS_RESPONSE=$(curl -s "${BASE_URL}/_nodes/stats/jvm,os,process?pretty=false" 2>/dev/null || echo "")

if [[ -n "${STATS_RESPONSE}" ]]; then
  # Extraction basique des statistiques JVM
  HEAP_USED=$(echo "${STATS_RESPONSE}" | grep -oE '"heap_used_percent":[0-9]+' | head -1 | grep -oE '[0-9]+' || echo "?")
  log_info "Utilisation du heap JVM (noeud 1) : ${HEAP_USED}%"
  if [[ "${HEAP_USED}" =~ ^[0-9]+$ ]] && [[ ${HEAP_USED} -gt 80 ]]; then
    log_warn "Utilisation du heap élevée (${HEAP_USED}%) — Augmentez Xmx si possible"
  fi
else
  log_warn "Impossible de récupérer les statistiques de noeuds"
fi

# Récapitulatif final
echo ""
echo -e "${BOLD}${BLUE}"
echo "════════════════════════════════════════════════════════════"
echo "  Rapport généré le : ${REPORT_TIME}"
echo "  Cluster : ${CLUSTER_NAME} | Statut : ${CLUSTER_STATUS} | Noeuds : ${NUM_NODES}"
echo "════════════════════════════════════════════════════════════"
echo -e "${NC}"
