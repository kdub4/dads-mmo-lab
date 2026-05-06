#!/bin/bash
# ============================================================
#  Dad's MMO Lab — Fix Docker After SteamOS Update
#  https://github.com/DadsMmoLab/dads-mmo-lab
#
#  Run this if Docker stops working after a SteamOS update
#  Usage: chmod +x fix-after-update.sh && ./fix-after-update.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}${BOLD}         ⚙️  DAD'S MMO LAB                        ${NC}${CYAN}║${NC}"
echo -e "${CYAN}║${WHITE}         Fix Docker After SteamOS Update          ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}SteamOS updates can wipe Docker and break the${NC}"
echo -e "${YELLOW}pacman keyring. This script fixes both!${NC}"
echo ""

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }

# ─────────────────────────────────────────
# STEP 1 — Disable read-only filesystem
# ─────────────────────────────────────────
print_info "Disabling SteamOS read-only filesystem..."
sudo steamos-readonly disable
print_success "Read-only disabled"

# ─────────────────────────────────────────
# STEP 2 — Fix pacman keyring
# ─────────────────────────────────────────
print_info "Rebuilding pacman keyring..."
sudo rm -rf /etc/pacman.d/gnupg 2>/dev/null || true
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo

# Use steamos-devmode for extra reliability
if command -v steamos-devmode &>/dev/null; then
    sudo steamos-devmode enable 2>/dev/null || true
fi

print_success "Keyring rebuilt"

# ─────────────────────────────────────────
# STEP 3 — Reinstall Docker
# ─────────────────────────────────────────
print_info "Updating keyring package..."
sudo pacman -Sy --noconfirm archlinux-keyring 2>/dev/null || true

print_info "Reinstalling Docker..."
sudo pacman -Sy --noconfirm docker docker-compose

print_success "Docker reinstalled"

# ─────────────────────────────────────────
# STEP 4 — Restart Docker service
# ─────────────────────────────────────────
print_info "Starting Docker service..."
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker
sleep 3

# ─────────────────────────────────────────
# STEP 5 — Verify
# ─────────────────────────────────────────
if docker ps &>/dev/null 2>&1 || sudo docker ps &>/dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   ✅ DOCKER IS WORKING AGAIN!                    ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Your WoW server should work normally now.${NC}"
    echo -e "${WHITE}Start it with: ${CYAN}cd ~/wow-server && ./start.sh${NC}"
else
    print_error "Docker still not responding."
    echo -e "${YELLOW}Try rebooting your Steam Deck and running this script again.${NC}"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}  📺 youtube.com/@DadsMmoLab${NC}"
echo -e "${WHITE}  📦 github.com/DadsMmoLab/dads-mmo-lab${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
