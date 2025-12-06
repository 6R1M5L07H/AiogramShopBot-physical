#!/bin/bash
# ============================================================================
# Migration Script: Update Production VPN Setup for New Port Allocation
# ============================================================================
#
# This script updates your filled docker-compose.prod-vpn.yml and .env
# to use the new port allocation that avoids conflicts with staging.
#
# CHANGES:
# - Container names: shopbot-* → shopbot-*-prod-vpn
# - Bot port: 5000 → 5100
# - Redis external port: 6379 → 6479
# - WEBAPP_PORT in .env: 5000 → 5100
# - Caddy reverse_proxy: upstreams 5000 → upstreams 5100
# - Firewall port: 5000 → 5100
#
# USAGE:
#   bash vpn/migrate-prod-vpn-ports.sh
#
# BACKUP:
#   Backups are created automatically before modifications
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Production VPN Port Migration Script ===${NC}\n"

# Check if files exist
if [ ! -f "docker-compose.prod-vpn.yml" ]; then
    echo -e "${RED}Error: docker-compose.prod-vpn.yml not found${NC}"
    echo "This script must be run from the project root directory"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env not found${NC}"
    echo "Make sure to update WEBAPP_PORT=5100 in your .env manually"
fi

# Create backups
echo -e "${YELLOW}Creating backups...${NC}"
cp docker-compose.prod-vpn.yml docker-compose.prod-vpn.yml.backup-$(date +%Y%m%d-%H%M%S)
if [ -f ".env" ]; then
    cp .env .env.backup-$(date +%Y%m%d-%H%M%S)
fi
echo -e "${GREEN}✓ Backups created${NC}\n"

# Update docker-compose.prod-vpn.yml
echo -e "${YELLOW}Updating docker-compose.prod-vpn.yml...${NC}"

# Container names
sed -i.tmp 's/container_name: shopbot-gluetun-prod$/container_name: shopbot-gluetun-prod-vpn/g' docker-compose.prod-vpn.yml
sed -i.tmp 's/container_name: shopbot-prod$/container_name: shopbot-prod-vpn/g' docker-compose.prod-vpn.yml
sed -i.tmp 's/container_name: shopbot-redis-prod$/container_name: shopbot-redis-prod-vpn/g' docker-compose.prod-vpn.yml

# Port mappings
sed -i.tmp 's/"5000:5000"/"5100:5100"/g' docker-compose.prod-vpn.yml
sed -i.tmp 's/"6379:6379"/"6479:6379"/g' docker-compose.prod-vpn.yml

# Caddy reverse proxy
sed -i.tmp 's/{{upstreams 5000}}/{{upstreams 5100}}/g' docker-compose.prod-vpn.yml

# Firewall ports
sed -i.tmp 's/FIREWALL_VPN_INPUT_PORTS=5000/FIREWALL_VPN_INPUT_PORTS=5100/g' docker-compose.prod-vpn.yml

# Clean up temp files
rm -f docker-compose.prod-vpn.yml.tmp

echo -e "${GREEN}✓ docker-compose.prod-vpn.yml updated${NC}\n"

# Update .env if it exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}Updating .env...${NC}"
    sed -i.tmp 's/^WEBAPP_PORT=5000$/WEBAPP_PORT=5100/g' .env
    rm -f .env.tmp
    echo -e "${GREEN}✓ .env updated${NC}\n"
else
    echo -e "${YELLOW}⚠ .env not found - remember to set WEBAPP_PORT=5100 manually${NC}\n"
fi

# Summary
echo -e "${GREEN}=== Migration Complete ===${NC}\n"
echo "Changes applied:"
echo "  - Container names: *-prod → *-prod-vpn"
echo "  - Bot port: 5000 → 5100"
echo "  - Redis port: 6379 → 6479"
echo "  - WEBAPP_PORT: 5000 → 5100"
echo ""
echo "Backups created:"
ls -1 *.backup-* 2>/dev/null | sed 's/^/  - /'
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes: diff docker-compose.prod-vpn.yml docker-compose.prod-vpn.yml.backup-*"
echo "  2. Verify .env has WEBAPP_PORT=5100"
echo "  3. Restart containers: docker-compose -f docker-compose.prod-vpn.yml down && docker-compose -f docker-compose.prod-vpn.yml up -d"
echo ""
echo -e "${GREEN}Done!${NC}"
