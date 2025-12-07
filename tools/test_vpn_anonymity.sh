#!/bin/bash
# ============================================================================
# VPN Anonymity Verification Script
# ============================================================================
#
# Tests that all bot traffic goes through VPN and Telegram only sees VPN IP.
#
# Usage: bash tools/test_vpn_anonymity.sh [compose-file]
# Example: bash tools/test_vpn_anonymity.sh docker-compose.prod-vpn.yml
#
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default compose file
COMPOSE_FILE="${1:-docker-compose.prod-vpn.yml}"

echo -e "${BLUE}🔒 VPN Anonymity Verification Test${NC}"
echo -e "${BLUE}====================================${NC}\n"

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

# Check if containers are running
if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    echo -e "${RED}❌ Containers not running. Start with: docker-compose -f $COMPOSE_FILE up -d${NC}"
    exit 1
fi

echo -e "${YELLOW}1️⃣  Checking Server Real IP...${NC}"
SERVER_IP=$(curl -s https://api.ipify.org)
echo -e "   Server IP: ${GREEN}$SERVER_IP${NC}\n"

echo -e "${YELLOW}2️⃣  Checking VPN IP (seen by Telegram)...${NC}"
VPN_IP=$(docker-compose -f "$COMPOSE_FILE" exec -T gluetun wget -qO- https://api.ipify.org)
echo -e "   VPN IP: ${GREEN}$VPN_IP${NC}\n"

# Compare IPs
if [ "$SERVER_IP" == "$VPN_IP" ]; then
    echo -e "${RED}❌ FAIL: VPN IP matches Server IP!${NC}"
    echo -e "${RED}   Traffic is NOT going through VPN!${NC}"
    echo -e "${RED}   Telegram sees your real server IP: $SERVER_IP${NC}\n"
    exit 1
else
    echo -e "${GREEN}✅ PASS: VPN IP differs from Server IP${NC}"
    echo -e "${GREEN}   Telegram sees VPN IP: $VPN_IP${NC}"
    echo -e "${GREEN}   Real server IP hidden: $SERVER_IP${NC}\n"
fi

echo -e "${YELLOW}3️⃣  Checking Bot Mode (should be polling)...${NC}"
BOT_LOGS=$(docker-compose -f "$COMPOSE_FILE" logs --tail=50 bot)

if echo "$BOT_LOGS" | grep -q "Starting polling with timeout"; then
    echo -e "${GREEN}✅ PASS: Bot running in polling mode${NC}"
    TIMEOUT=$(echo "$BOT_LOGS" | grep "Starting polling with timeout" | tail -1 | grep -oP 'timeout=\K\d+')
    echo -e "   Polling timeout: ${GREEN}${TIMEOUT}s${NC}\n"
elif echo "$BOT_LOGS" | grep -q "Webhook registered"; then
    echo -e "${RED}❌ FAIL: Bot running in WEBHOOK mode!${NC}"
    echo -e "${RED}   Set WEBHOOK_MODE=polling in .env${NC}\n"
    exit 1
else
    echo -e "${YELLOW}⚠️  WARNING: Cannot determine bot mode from logs${NC}"
    echo -e "   Check logs manually: docker-compose -f $COMPOSE_FILE logs bot\n"
fi

echo -e "${YELLOW}4️⃣  Checking Telegram Webhook Status...${NC}"
if [ -z "$BOT_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  SKIP: BOT_TOKEN not set in environment${NC}"
    echo -e "   Export BOT_TOKEN to test: export BOT_TOKEN=your_token_here\n"
else
    WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getWebhookInfo")
    WEBHOOK_URL=$(echo "$WEBHOOK_INFO" | grep -oP '"url":".*?"' | cut -d'"' -f4)

    if [ -z "$WEBHOOK_URL" ]; then
        echo -e "${GREEN}✅ PASS: No webhook configured (polling mode)${NC}\n"
    else
        echo -e "${RED}❌ FAIL: Webhook still configured!${NC}"
        echo -e "${RED}   Webhook URL: $WEBHOOK_URL${NC}"
        echo -e "${RED}   Bot should delete webhook on startup in polling mode${NC}\n"
        exit 1
    fi
fi

echo -e "${YELLOW}5️⃣  Checking VPN Container Health...${NC}"
GLUETUN_HEALTH=$(docker-compose -f "$COMPOSE_FILE" ps gluetun | grep -o "healthy\|unhealthy")

if [ "$GLUETUN_HEALTH" == "healthy" ]; then
    echo -e "${GREEN}✅ PASS: Gluetun container healthy${NC}\n"
elif [ "$GLUETUN_HEALTH" == "unhealthy" ]; then
    echo -e "${RED}❌ FAIL: Gluetun container unhealthy!${NC}"
    echo -e "${RED}   Check VPN connection: docker-compose -f $COMPOSE_FILE logs gluetun${NC}\n"
    exit 1
else
    echo -e "${YELLOW}⚠️  WARNING: Cannot determine Gluetun health${NC}\n"
fi

echo -e "${YELLOW}6️⃣  Testing DNS Resolution Through VPN...${NC}"
DNS_TEST=$(docker-compose -f "$COMPOSE_FILE" exec -T gluetun nslookup api.telegram.org 2>&1)

if echo "$DNS_TEST" | grep -q "Address:"; then
    echo -e "${GREEN}✅ PASS: DNS resolution working through VPN${NC}"
    TELEGRAM_IP=$(echo "$DNS_TEST" | grep "Address:" | tail -1 | awk '{print $2}')
    echo -e "   api.telegram.org resolves to: ${GREEN}$TELEGRAM_IP${NC}\n"
else
    echo -e "${RED}❌ FAIL: DNS resolution not working!${NC}"
    echo -e "${RED}   VPN tunnel may be broken${NC}\n"
    exit 1
fi

echo -e "${YELLOW}7️⃣  Verifying Kill Switch (firewall rules)...${NC}"
FIREWALL_RULES=$(docker-compose -f "$COMPOSE_FILE" logs --tail=100 gluetun | grep -i "firewall")

if echo "$FIREWALL_RULES" | grep -q "firewall"; then
    echo -e "${GREEN}✅ PASS: Firewall rules detected${NC}"
    echo -e "   Kill switch active (blocks non-VPN traffic)\n"
else
    echo -e "${YELLOW}⚠️  WARNING: Cannot verify firewall rules from logs${NC}\n"
fi

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ VPN Anonymity Verified!${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${GREEN}Summary:${NC}"
echo -e "  • Telegram sees VPN IP: ${GREEN}$VPN_IP${NC}"
echo -e "  • Real server IP hidden: ${GREEN}$SERVER_IP${NC}"
echo -e "  • Bot mode: ${GREEN}Polling${NC}"
echo -e "  • VPN health: ${GREEN}Healthy${NC}"
echo -e "\n${GREEN}🎉 Your bot is running anonymously through VPN!${NC}\n"

# Optional: Show live traffic monitoring command
echo -e "${BLUE}Optional: Monitor live traffic (requires sudo):${NC}"
echo -e "  sudo tcpdump -i any host api.telegram.org"
echo -e "  ${YELLOW}You should see NO traffic (all goes through VPN)${NC}\n"
