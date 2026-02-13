#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="${AKS_CLUSTER_NAME:-aks-cluster-demo}"
RESOURCE_GROUP="${RESOURCE_GROUP:-aks-demo-rg}"

echo "🔧 Updating kubeconfig for AKS cluster..."
echo "  Cluster: $CLUSTER_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo ""

# Get credentials
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --overwrite-existing

