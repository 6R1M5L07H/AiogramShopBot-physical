#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Parse command-line flags
ENVIRONMENT=""
EDITION=""
VPN_MODE=""
REMOTE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --edition)
            EDITION="$2"
            shift 2
            ;;
        --vpn)
            VPN_MODE="$2"
            shift 2
            ;;
        --remote)
            REMOTE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --env <staging|prod>              Environment to deploy to"
            echo "  --edition <opensource|enterprise> Edition to deploy"
            echo "  --vpn <enabled|disabled>          VPN mode (enterprise only)"
            echo "  --remote <origin|origin-private>  Git remote to pull from"
            echo ""
            echo "If options are not specified, you will be prompted interactively."
            echo ""
            echo "Examples:"
            echo "  $0                                           # Interactive mode"
            echo "  $0 --env prod --edition opensource          # Production, open-source"
            echo "  $0 --env prod --edition enterprise --vpn enabled --remote origin-private"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  🚀 ShopForge Deployment Tool"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "📍 Current branch: $CURRENT_BRANCH"
echo ""

# ============================================================================
# STEP 1: Environment Selection (staging or prod)
# ============================================================================
if [[ -z "$ENVIRONMENT" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 1: Select Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1) staging - Development/Testing environment"
    echo "  2) prod    - Production environment"
    echo ""
    read -p "Choose environment (1/2): " -r ENV_CHOICE
    echo ""

    case $ENV_CHOICE in
        1)
            ENVIRONMENT="staging"
            ;;
        2)
            ENVIRONMENT="prod"
            ;;
        *)
            echo "❌ Invalid choice. Deployment cancelled."
            exit 1
            ;;
    esac
fi

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    echo "❌ Error: Environment must be 'staging' or 'prod'"
    exit 1
fi

echo "✅ Environment: $ENVIRONMENT"
echo ""

# ============================================================================
# STEP 2: Edition Selection (opensource or enterprise)
# ============================================================================
if [[ -z "$EDITION" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 2: Select Edition"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1) opensource  - Public open-source version (GitHub)"
    echo "  2) enterprise  - Private enterprise version with VPN support"
    echo ""
    read -p "Choose edition (1/2): " -r EDITION_CHOICE
    echo ""

    case $EDITION_CHOICE in
        1)
            EDITION="opensource"
            ;;
        2)
            EDITION="enterprise"
            ;;
        *)
            echo "❌ Invalid choice. Deployment cancelled."
            exit 1
            ;;
    esac
fi

if [[ "$EDITION" != "opensource" && "$EDITION" != "enterprise" ]]; then
    echo "❌ Error: Edition must be 'opensource' or 'enterprise'"
    exit 1
fi

echo "✅ Edition: $EDITION"
echo ""

# ============================================================================
# STEP 3: Enterprise Feature Validation
# ============================================================================
if [[ "$EDITION" == "enterprise" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 3: Validating Enterprise Features"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if VPN docker-compose templates exist
    if [[ ! -f "docker-compose.${ENVIRONMENT}-vpn.yml.template" ]]; then
        echo "❌ Error: Enterprise features not found in this codebase!"
        echo "   Missing: docker-compose.${ENVIRONMENT}-vpn.yml.template"
        echo ""
        echo "   Enterprise features are only available in a licensed version."
        echo "   Please use --edition opensource for public deployments."
        exit 1
    fi

    echo "✅ Enterprise features validated"
    echo ""
fi

# ============================================================================
# STEP 4: VPN Mode Selection (enterprise only)
# ============================================================================
if [[ "$EDITION" == "enterprise" ]]; then
    if [[ -z "$VPN_MODE" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "STEP 4: Select VPN Mode"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  1) enabled  - Deploy with VPN (maximum anonymity)"
        echo "  2) disabled - Deploy without VPN (standard enterprise)"
        echo ""
        read -p "Choose VPN mode (1/2): " -r VPN_CHOICE
        echo ""

        case $VPN_CHOICE in
            1)
                VPN_MODE="enabled"
                ;;
            2)
                VPN_MODE="disabled"
                ;;
            *)
                echo "❌ Invalid choice. Deployment cancelled."
                exit 1
                ;;
        esac
    fi

    if [[ "$VPN_MODE" != "enabled" && "$VPN_MODE" != "disabled" ]]; then
        echo "❌ Error: VPN mode must be 'enabled' or 'disabled'"
        exit 1
    fi

    echo "✅ VPN mode: $VPN_MODE"
    echo ""
else
    VPN_MODE="disabled"
fi

# ============================================================================
# STEP 5: Determine Git Remote
# ============================================================================
if [[ -z "$REMOTE" ]]; then
    if [[ "$EDITION" == "enterprise" ]]; then
        REMOTE="origin-private"
    else
        REMOTE="origin"
    fi
fi

# Validate remote exists
if ! git remote | grep -q "^${REMOTE}$"; then
    echo "❌ Error: Remote '$REMOTE' does not exist!"
    echo "Available remotes:"
    git remote -v
    exit 1
fi

# ============================================================================
# STEP 6: Determine Docker Compose File
# ============================================================================
if [[ "$EDITION" == "enterprise" && "$VPN_MODE" == "enabled" ]]; then
    COMPOSE_FILE="docker-compose.${ENVIRONMENT}-vpn.yml"
else
    COMPOSE_FILE="docker-compose.${ENVIRONMENT}.yml"
fi

# Check if docker-compose file exists
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "⚠️  Warning: $COMPOSE_FILE not found, will be generated from template"
    if [[ ! -f "${COMPOSE_FILE}.template" ]]; then
        echo "❌ Error: Template ${COMPOSE_FILE}.template not found!"
        exit 1
    fi
fi

# ============================================================================
# STEP 7: Show Deployment Summary
# ============================================================================
REMOTE_URL=$(git remote get-url "$REMOTE")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Deployment Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Environment:      $ENVIRONMENT"
echo "  Edition:          $EDITION"
if [[ "$EDITION" == "enterprise" ]]; then
    echo "  VPN Mode:         $VPN_MODE"
fi
echo "  Git Remote:       $REMOTE"
echo "  Remote URL:       $REMOTE_URL"
echo "  Branch:           $CURRENT_BRANCH"
echo "  Docker Compose:   $COMPOSE_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo -e "${RED}⚠️  WARNING: PRODUCTION DEPLOYMENT${NC}"
    echo -e "${RED}   This will update the LIVE production system!${NC}"
    echo ""
fi

if [[ "$EDITION" == "enterprise" && "$VPN_MODE" == "enabled" ]]; then
    echo -e "${YELLOW}🔒 Enterprise deployment with VPN anonymity${NC}"
    echo ""
fi

read -p "Continue deployment? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# ============================================================================
# STEP 8: Pull Latest Changes
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Pulling Latest Changes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Remote: $REMOTE/$CURRENT_BRANCH"
echo ""

git pull "$REMOTE" "$CURRENT_BRANCH"

echo ""
echo "✅ Code updated"
echo ""

# ============================================================================
# STEP 9: Build and Deploy
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building and Deploying"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Docker Compose: $COMPOSE_FILE"
echo ""

# Build all containers
echo "Building containers..."
docker-compose -f "$COMPOSE_FILE" build

echo ""
echo "Starting all services..."
docker-compose -f "$COMPOSE_FILE" up -d

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 View logs:"

if [[ "$EDITION" == "enterprise" && "$VPN_MODE" == "enabled" ]]; then
    CONTAINER_NAME="shopbot-${ENVIRONMENT}-vpn"
else
    CONTAINER_NAME="shopbot-${ENVIRONMENT}"
fi

echo "   docker logs $CONTAINER_NAME -f"
echo ""
echo "📋 View all services:"
echo "   docker-compose -f $COMPOSE_FILE ps"
echo ""
