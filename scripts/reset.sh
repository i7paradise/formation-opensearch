#!/bin/bash

# =============================================================================
# reset.sh — Réinitialisation complète des données de formation OpenSearch
# Auteur : Kit de formation OpenSearch 3.6
# Usage  : ./reset.sh
# ATTENTION : Ce script supprime tous les indices de formation et recharge
#             les données de démonstration depuis zéro.
# =============================================================================

set -euo pipefail

# URL de base de l'API OpenSearch
BASE_URL="http://localhost:9200"

# Répertoire des scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
# Confirmation utilisateur avant suppression
# -----------------------------------------------------------------------------
echo -e "${BOLD}${RED}"
echo "============================================================"
echo "  RÉINITIALISATION DES DONNÉES DE FORMATION"
echo "============================================================"
echo -e "${NC}"
echo -e "${YELLOW}ATTENTION : Cette opération va supprimer définitivement :${NC}"
echo "  - L'index 'products' et toutes ses variantes (products-v1, products-v2)"
echo "  - L'index 'stores'"
echo "  - L'index 'logs'"
echo ""
echo -e "${YELLOW}Les données seront rechargées depuis les fichiers de démonstration.${NC}"
echo ""

# Demander confirmation (sauf si mode non-interactif)
if [[ -t 0 ]]; then
  read -r -p "Confirmer la réinitialisation ? [o/N] : " CONFIRM
  if [[ ! "${CONFIRM}" =~ ^[oOyY]$ ]]; then
    log_info "Réinitialisation annulée."
    exit 0
  fi
else
  log_warn "Mode non-interactif détecté — réinitialisation automatique"
fi

# -----------------------------------------------------------------------------
# Vérification qu'OpenSearch est disponible
# -----------------------------------------------------------------------------
log_step "Vérification de la disponibilité d'OpenSearch..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE_URL}/_cluster/health" 2>/dev/null || echo "000")
if [[ "${HTTP_CODE}" != "200" ]]; then
  log_error "OpenSearch n'est pas accessible (code HTTP : ${HTTP_CODE})."
  log_error "Vérifiez que le conteneur est démarré : docker ps"
  log_error "Lancez l'environnement : bash ${SCRIPT_DIR}/setup.sh"
  exit 1
fi
log_success "OpenSearch accessible sur ${BASE_URL}"

# -----------------------------------------------------------------------------
# Étape 1 : Suppression des indices
# -----------------------------------------------------------------------------
log_step "Suppression des indices de formation..."

# Liste des indices à supprimer (avec patterns wildcard)
INDICES_TO_DELETE=(
  "products"
  "products-v1"
  "products-v2"
  "products-*"
  "stores"
  "logs"
  "logs-*"
)

DELETED_COUNT=0

for INDEX in "${INDICES_TO_DELETE[@]}"; do
  log_info "Suppression de l'index '${INDEX}'..."

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/${INDEX}" 2>/dev/null || echo "000")

  case "${HTTP_CODE}" in
    200)
      log_success "Index '${INDEX}' supprimé"
      DELETED_COUNT=$((DELETED_COUNT + 1))
      ;;
    404)
      log_info "Index '${INDEX}' n'existe pas (ignoré)"
      ;;
    *)
      log_warn "Suppression de '${INDEX}' : réponse HTTP ${HTTP_CODE} (ignoré)"
      ;;
  esac
done

echo ""
log_success "${DELETED_COUNT} index/indices supprimé(s)"

# Pause pour laisser OpenSearch finaliser les suppressions
sleep 2

# -----------------------------------------------------------------------------
# Étape 2 : Rechargement des données de démonstration
# -----------------------------------------------------------------------------
log_step "Rechargement des données de démonstration..."

SEED_SCRIPT="${SCRIPT_DIR}/seed-data.sh"

if [[ ! -f "${SEED_SCRIPT}" ]]; then
  log_error "Script seed-data.sh introuvable : ${SEED_SCRIPT}"
  exit 1
fi

if bash "${SEED_SCRIPT}"; then
  log_success "Données rechargées avec succès !"
else
  log_error "Erreur lors du rechargement des données."
  log_error "Relancez manuellement : bash ${SEED_SCRIPT}"
  exit 1
fi

# -----------------------------------------------------------------------------
# Confirmation finale
# -----------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}"
echo "============================================================"
echo "  Réinitialisation terminée avec succès !"
echo "============================================================"
echo -e "${NC}"
echo -e "Les données de formation sont prêtes."
echo -e "  Vérification des indices : ${CYAN}${BASE_URL}/_cat/indices?v${NC}"
echo -e "  Santé du cluster        : ${CYAN}bash ${SCRIPT_DIR}/check-health.sh${NC}"
