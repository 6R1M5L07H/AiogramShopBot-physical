#!/bin/bash
set -e

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Parse command-line flags
REMOTE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote)
            REMOTE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--remote origin|origin-private]"
            echo ""
            echo "Options:"
            echo "  --remote <name>    Specify git remote (origin or origin-private)"
            echo ""
            echo "If --remote is not specified, you will be prompted to choose."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "⚠️  PRODUCTION DEPLOYMENT"
echo "========================"
echo "This will deploy to PRODUCTION environment."
echo ""
echo "📍 Deploying branch: $CURRENT_BRANCH"
echo ""

# Remote selection (if not specified via flag)
if [[ -z "$REMOTE" ]]; then
    echo "Select deployment source:"
    echo "  1) origin (GitHub - Public/Open-Source)"
    echo "  2) origin-private (Private Server - Enterprise Features)"
    echo ""
    read -p "Choose remote (1/2): " -r REMOTE_CHOICE
    echo ""

    case $REMOTE_CHOICE in
        1)
            REMOTE="origin"
            ;;
        2)
            REMOTE="origin-private"
            ;;
        *)
            echo "❌ Invalid choice. Deployment cancelled."
            exit 1
            ;;
    esac
fi

# Validate remote exists
if ! git remote | grep -q "^${REMOTE}$"; then
    echo "❌ Error: Remote '$REMOTE' does not exist!"
    echo "Available remotes:"
    git remote -v
    exit 1
fi

# Show remote URL for confirmation
REMOTE_URL=$(git remote get-url "$REMOTE")
echo "🌐 Remote: $REMOTE ($REMOTE_URL)"
echo ""

# Enterprise features warning for origin-private
if [[ "$REMOTE" == "origin-private" ]]; then
    echo "⚠️  DEPLOYING FROM PRIVATE REMOTE (Enterprise Features)"
fi

read -p "Continue deployment? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

echo "🔄 Pulling latest changes from $REMOTE/$CURRENT_BRANCH..."
git pull "$REMOTE" "$CURRENT_BRANCH"

echo "🔨 Building bot container..."
docker-compose -f docker-compose.prod.yml build bot

echo "🚀 Restarting bot..."
docker-compose -f docker-compose.prod.yml up -d bot

echo "✅ Deploy completed!"
echo ""
echo "📋 View logs:"
echo "   docker logs shopbot-prod -f"
