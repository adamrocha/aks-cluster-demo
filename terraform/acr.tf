# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.aks_demo_rg.name
  location            = azurerm_resource_group.aks_demo_rg.location
  sku                 = var.acr_sku
  admin_enabled       = false # Use managed identity instead

  # Enable advanced features for Premium SKU
  dynamic "georeplications" {
    for_each = var.acr_sku == "Premium" ? var.acr_georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
    }
  }

  tags = var.tags
}

# Attach ACR to AKS cluster using AcrPull role
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Update kubeconfig after cluster is ready
resource "terraform_data" "update_kubeconfig" {
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_role_assignment.aks_acr_pull
  ]

  triggers_replace = {
    cluster_name = azurerm_kubernetes_cluster.aks.id
  }

  provisioner "local-exec" {
    command     = "az aks get-credentials --resource-group ${var.resource_group} --name ${var.cluster_name} --overwrite-existing"
    interpreter = ["bash", "-c"]
  }
}

# Build and push Docker image to ACR
resource "terraform_data" "docker_build_push" {
  depends_on = [
    azurerm_container_registry.acr,
    azurerm_role_assignment.aks_acr_pull
  ]

  triggers_replace = {
    image_tag      = var.image_tag
    platforms      = join(",", var.platforms)
    dockerfile_md5 = filemd5("../app/Dockerfile")
    acr_name       = azurerm_container_registry.acr.name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🐳 Building and pushing Docker image to ACR"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      
      ACR_NAME="${azurerm_container_registry.acr.name}"
      ACR_LOGIN_SERVER="${azurerm_container_registry.acr.login_server}"
      IMAGE_TAG="${var.image_tag}"
      PLATFORMS="${join(",", var.platforms)}"
      REPO_NAME="${var.repo_name}"
      
      echo "📦 Registry: $ACR_LOGIN_SERVER"
      echo "🏷️  Image: $REPO_NAME:$IMAGE_TAG"
      echo "🔧 Platforms: $PLATFORMS"
      echo ""
      
      # Login to ACR
      echo "🔐 Logging in to ACR..."
      az acr login --name "$ACR_NAME"
      
      # Create buildx builder if not exists
      echo "🔨 Setting up Docker buildx..."
      docker buildx create --use --name acr-builder 2>/dev/null || docker buildx use acr-builder || true
      
      # Build and push multi-arch image
      echo "🚀 Building multi-architecture image..."
      docker buildx build \
        --platform "$PLATFORMS" \
        --tag "$ACR_LOGIN_SERVER/$REPO_NAME:$IMAGE_TAG" \
        --tag "$ACR_LOGIN_SERVER/$REPO_NAME:latest" \
        --push \
        ../app/
      
      echo ""
      echo "✅ Image pushed successfully!"
      echo "📍 Full image path: $ACR_LOGIN_SERVER/$REPO_NAME:$IMAGE_TAG"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    EOT

    interpreter = ["bash", "-c"]
  }
}

# Verify image was pushed successfully
data "external" "verify_image" {
  depends_on = [terraform_data.docker_build_push]

  program = ["bash", "-c", <<-EOT
    set -e
    ACR_NAME="${azurerm_container_registry.acr.name}"
    REPO_NAME="${var.repo_name}"
    IMAGE_TAG="${var.image_tag}"
    
    # Check if image exists
    if az acr repository show-tags \
        --name "$ACR_NAME" \
        --repository "$REPO_NAME" \
        --output json 2>/dev/null | grep -q "$IMAGE_TAG"; then
      echo "{\"exists\": \"true\", \"registry\": \"$ACR_NAME\", \"repository\": \"$REPO_NAME\", \"tag\": \"$IMAGE_TAG\"}"
    else
      echo "{\"exists\": \"false\", \"registry\": \"$ACR_NAME\", \"repository\": \"$REPO_NAME\", \"tag\": \"$IMAGE_TAG\"}"
    fi
  EOT
  ]
}
