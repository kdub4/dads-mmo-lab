#!/bin/bash
# ============================================================
#  Dad's MMO Lab — WoW Offline Server UNINSTALLER
#  Completely removes the AzerothCore server from your Steam Deck
#
#  https://github.com/DadsMmoLab/dads-mmo-lab
#
#  Usage:
#    chmod +x uninstall.sh
#    ./uninstall.sh
#
#  What this removes:
#    - All running Docker containers (worldserver, authserver, database)
#    - All Docker images downloaded for the server
#    - The Docker volume containing your character data
#    - The ~/wow-server folder and all its contents
#
#  What this does NOT touch:
#    - Your WoW 3.3.5a client files
#    - Docker itself (in case you use it for other things)
#    - Any other games or projects
#
#  ⚠️  THIS WILL DELETE YOUR CHARACTERS AND PROGRESS ⚠️
#  Make a backup first if you want to keep your character data!
# ============================================================

# ─────────────────────────────────────────
# COLORS
# ─────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

print_header() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${WHITE}${BOLD}         ⚙️  DAD'S MMO LAB                        ${NC}${RED}║${NC}"
    echo -e "${RED}║${WHITE}         WoW Server — UNINSTALLER                 ${NC}${RED}║${NC}"
    echo -e "${RED}║${BLUE}         github.com/DadsMmoLab/dads-mmo-lab       ${NC}${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD} $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

ask_yes_no() {
    while true; do
        echo -e "${WHITE}$1 (y/n): ${NC}"
        read -r answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

INSTALL_DIR="$HOME/wow-server"

# ─────────────────────────────────────────
# START
# ─────────────────────────────────────────
clear
print_header

echo -e "${WHITE}This will completely remove your WoW offline server.${NC}"
echo ""
echo -e "${YELLOW}This includes:${NC}"
echo -e "  • All server containers (worldserver, authserver, database)"
echo -e "  • All downloaded Docker images for the server"
echo -e "  • Your server folder: ${CYAN}$INSTALL_DIR${NC}"
echo -e "  • ${RED}All character data and progress${NC}"
echo ""
echo -e "${GREEN}This does NOT touch:${NC}"
echo -e "  • Your WoW 3.3.5a client files"
echo -e "  • Docker itself"
echo -e "  • Any other projects"
echo ""

# ─────────────────────────────────────────
# BACKUP OFFER
# ─────────────────────────────────────────
print_warning "Do you want to back up your character data first?"
echo -e "${BLUE}ℹ️  This saves your characters, items, and progress to a backup file.${NC}"
echo ""

if ask_yes_no "Create a backup before uninstalling?"; then

    BACKUP_DIR="$HOME/wow-server-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    print_info "Backing up character database..."

    if docker ps | grep -q "ac_database"; then
        docker exec ac_database mysqldump \
            -uroot -pazeroth \
            --databases acore_characters acore_auth \
            > "$BACKUP_DIR/characters_backup.sql" 2>/dev/null

        if [ -f "$BACKUP_DIR/characters_backup.sql" ] && \
           [ -s "$BACKUP_DIR/characters_backup.sql" ]; then
            print_success "Backup saved to: $BACKUP_DIR/characters_backup.sql"
            print_info "Keep this file if you want to restore your characters later!"
        else
            print_warning "Backup may be incomplete — database might not be running."
        fi
    else
        print_warning "Database container not running — skipping backup."
        print_info "If you want to back up manually, start the server first then re-run this script."
    fi
fi

echo ""

# ─────────────────────────────────────────
# FINAL CONFIRMATION
# ─────────────────────────────────────────
echo -e "${RED}${BOLD}⚠️  THIS CANNOT BE UNDONE ⚠️${NC}"
echo ""

if ! ask_yes_no "Are you absolutely sure you want to uninstall?"; then
    echo ""
    echo -e "${GREEN}Smart choice! Your server is safe. Run this script again when you're ready.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${RED}Last chance — type DELETE to confirm:${NC} "
read -r confirm
if [ "$confirm" != "DELETE" ]; then
    echo ""
    echo -e "${GREEN}Cancelled — your server is safe!${NC}"
    echo ""
    exit 0
fi

echo ""
print_info "Uninstalling... this will take about 30-60 seconds."

# ─────────────────────────────────────────
# STEP 1 — STOP AND REMOVE CONTAINERS
# ─────────────────────────────────────────
print_step "STEP 1/4 — Stopping Server"

if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    cd "$INSTALL_DIR"
    docker compose down --volumes --remove-orphans 2>/dev/null || \
    sudo docker compose down --volumes --remove-orphans 2>/dev/null || true
    print_success "Server stopped and containers removed"
else
    # Try to stop containers directly if compose file is missing
    for container in ac_worldserver ac_authserver ac_database; do
        if docker ps -a | grep -q "$container"; then
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
            print_success "Removed container: $container"
        fi
    done
fi

# ─────────────────────────────────────────
# STEP 2 — REMOVE DOCKER IMAGES
# ─────────────────────────────────────────
print_step "STEP 2/4 — Removing Docker Images"

IMAGES=(
    "azerothcore/azerothcore:worldserver"
    "azerothcore/azerothcore:authserver"
    "azerothcore/azerothcore:database"
    "mysql:8.0"
)

for image in "${IMAGES[@]}"; do
    if docker images | grep -q "${image%%:*}"; then
        docker rmi "$image" 2>/dev/null || true
        print_success "Removed image: $image"
    fi
done

# Remove any dangling images
docker image prune -f 2>/dev/null || true
print_success "Cleaned up unused images"

# ─────────────────────────────────────────
# STEP 3 — REMOVE DOCKER VOLUME
# ─────────────────────────────────────────
print_step "STEP 3/4 — Removing Database Volume"

if docker volume ls | grep -q "dads_mmo_wow_db"; then
    docker volume rm dads_mmo_wow_db 2>/dev/null || true
    print_success "Removed database volume"
else
    # Try generic volume name as fallback
    docker volume rm wow-server_ac-database 2>/dev/null || true
    print_success "Removed database volume"
fi

# Remove the docker network
docker network rm dads_mmo_network 2>/dev/null || true

# ─────────────────────────────────────────
# STEP 4 — REMOVE SERVER FOLDER
# ─────────────────────────────────────────
print_step "STEP 4/4 — Removing Server Files"

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    print_success "Removed server folder: $INSTALL_DIR"
else
    print_info "Server folder not found — already removed"
fi

# ─────────────────────────────────────────
# DONE
# ─────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   ✅ UNINSTALL COMPLETE                           ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}Your WoW server has been completely removed.${NC}"
echo -e "${WHITE}Your WoW client files are untouched.${NC}"
echo ""

if [ -d "$HOME/wow-server-backup-"* ] 2>/dev/null; then
    echo -e "${CYAN}Your backup is saved at:${NC}"
    ls -d "$HOME"/wow-server-backup-* 2>/dev/null
    echo -e "${CYAN}Keep it safe if you want to restore your characters!${NC}"
    echo ""
fi

echo -e "${WHITE}Want to reinstall from scratch? Just run:${NC}"
echo -e "  ${CYAN}chmod +x install.sh && ./install.sh${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}  📺 youtube.com/@DadsMmoLab${NC}"
echo -e "${WHITE}  📦 github.com/DadsMmoLab/dads-mmo-lab${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}${BOLD}See you in Azeroth again soon. ⚔️${NC}"
echo ""
