#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get values from Terraform outputs or environment variables
if [[ -f "terraform/terraform.tfstate" ]]; then
    echo "🔍 Reading ACR info from Terraform state..."
    ACR_NAME=$(terraform -chdir=terraform output -raw acr_name 2>/dev/null || echo "")
    ACR_LOGIN_SERVER=$(terraform -chdir=terraform output -raw acr_login_server 2>/dev/null || echo "")
    IMAGE_TAG=$(terraform -chdir=terraform output -json | jq -r '.image_full_path.value' 2>/dev/null | cut -d: -f2 || echo "v1.0.0")
    REPO_NAME=$(terraform -chdir=terraform output -json | jq -r '.image_full_path.value' 2>/dev/null | cut -d/ -f2 | cut -d: -f1 || echo "hello-world-demo")
fi

# Fallback to environment variables or defaults
ACR_NAME="${ACR_NAME:-${AZURE_ACR_NAME:-aksdemoacr2026}}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-$ACR_NAME.azurecr.io}"
REPO_NAME="${REPO_NAME:-hello-world-demo}"
IMAGE_TAG="${IMAGE_TAG:-${IMAGE_VERSION:-v1.0.0}}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🐳 Docker Image Build and Push to ACR${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Registry:${NC}   $ACR_LOGIN_SERVER"
echo -e "${GREEN}Repository:${NC} $REPO_NAME"
echo -e "${GREEN}Tag:${NC}        $IMAGE_TAG"
echo -e "${GREEN}Platforms:${NC}  $PLATFORMS"
echo ""

# Check if ACR exists
echo "🔍 Checking if ACR exists..."
if ! az acr show --name "$ACR_NAME" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: ACR '$ACR_NAME' not found${NC}"
    echo ""
    echo "Available container registries:"
    az acr list --query "[].{Name:name, ResourceGroup:resourceGroup, LoginServer:loginServer}" -o table
    exit 1
fi

echo -e "${GREEN}✅ ACR found${NC}"
echo ""

# Login to ACR
echo "🔐 Logging in to ACR..."
az acr login --name "$ACR_NAME"
echo -e "${GREEN}✅ Logged in successfully${NC}"
echo ""

# Check if docker buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker buildx is not available${NC}"
    echo "Please install Docker Desktop or enable buildx in Docker"
    exit 1
fi

# Create or use buildx builder
echo "🔨 Setting up Docker buildx..."
if ! docker buildx inspect acr-builder >/dev/null 2>&1; then
    echo "Creating new buildx builder: acr-builder"
    docker buildx create --name acr-builder --use
else
    echo "Using existing buildx builder: acr-builder"
    docker buildx use acr-builder
fi
echo -e "${GREEN}✅ Buildx ready${NC}"
echo ""

# Build and push the image
echo "🚀 Building multi-architecture Docker image..."
echo "   This may take a few minutes..."
echo ""

docker buildx build \
    --platform "$PLATFORMS" \
    --tag "$ACR_LOGIN_SERVER/$REPO_NAME:$IMAGE_TAG" \
    --tag "$ACR_LOGIN_SERVER/$REPO_NAME:latest" \
    --push \
    --progress=plain \
    ./app/

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Image pushed successfully!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}Image Details:${NC}"
echo "  Full path: $ACR_LOGIN_SERVER/$REPO_NAME:$IMAGE_TAG"
echo "  Latest:    $ACR_LOGIN_SERVER/$REPO_NAME:latest"
echo ""

# Verify the image was pushed
echo "🔍 Verifying image in ACR..."
if az acr repository show-tags \
    --name "$ACR_NAME" \
    --repository "$REPO_NAME" \
    --output table 2>/dev/null | grep -q "$IMAGE_TAG"; then
    echo -e "${GREEN}✅ Image verified in ACR${NC}"
    echo ""
    echo "📋 Available tags for $REPO_NAME:"
    az acr repository show-tags \
        --name "$ACR_NAME" \
        --repository "$REPO_NAME" \
        --output table
else
    echo -e "${RED}❌ Warning: Could not verify image in ACR${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Build complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
