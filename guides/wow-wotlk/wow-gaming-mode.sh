#!/bin/bash
# ============================================================
#  Dad's MMO Lab — WoW Gaming Mode Launcher
#  Starts the server, waits for you to finish playing,
#  then shuts everything down cleanly.
#
#  Add this as a Non-Steam game to launch from Gaming Mode!
# ============================================================

# Check server is installed
if [ ! -d ~/wow-server ]; then
    echo "========================================"
    echo "  ❌ WoW server not found!"
    echo "  Please run install.sh first."
    echo "  github.com/DadsMmoLab/dads-mmo-lab"
    echo "========================================"
    read
    exit 1
fi

cd ~/wow-server

echo "========================================"
echo "  ⚔️  DAD'S MMO LAB"
echo "  WoW Offline Server"
echo "========================================"
echo ""
echo "  Starting server..."
echo ""

# Start server without phpMyAdmin
docker compose up -d --scale phpmyadmin=0

echo ""
echo "  Waiting for world server..."
echo ""

# Wait for world server to be ready
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if docker logs acore-docker-ac-worldserver-1 2>&1 | grep -q "World initialized"; then
        break
    fi
    printf "."
    sleep 3
    ELAPSED=$((ELAPSED + 3))
done

echo ""
echo ""
echo "========================================"
echo "  ✅ SERVER IS READY!"
echo "  Launch WoW from your Steam library"
echo ""
echo "  Press ENTER when done playing"
echo "  to shut down safely."
echo "========================================"
echo ""

read

echo ""
echo "  Shutting down server..."
echo ""

docker compose down

echo ""
echo "========================================"
echo "  ✅ Server stopped! Safe to close."
echo "========================================"
echo ""

exec bash
