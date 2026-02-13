# Resource Group
resource "azurerm_resource_group" "aks_demo_rg" {
  name     = var.resource_group
  location = var.location

  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  # checkov:skip=CKV_AZURE_170: Will switch to "Standard" SKU when EncryptionAtHost is enabled
  # checkov:skip=CKV_AZURE_227: Subscription does not enable EncryptionAtHost
  name                      = var.cluster_name
  location                  = var.location
  resource_group_name       = azurerm_resource_group.aks_demo_rg.name
  dns_prefix                = var.dns_prefix
  kubernetes_version        = var.kubernetes_version
  local_account_disabled    = false
  private_cluster_enabled   = true
  automatic_upgrade_channel = "stable"
  sku_tier                  = "Free"

  default_node_pool {
    name                         = var.node_pool
    vm_size                      = var.vm_size
    auto_scaling_enabled         = var.auto_scaling_enabled
    min_count                    = var.min_count
    max_count                    = var.max_count
    max_pods                     = 50
    os_disk_type                 = "Ephemeral"
    host_encryption_enabled      = false
    os_disk_size_gb              = var.os_disk_size_gb
    only_critical_addons_enabled = true
    type                         = "VirtualMachineScaleSets"

    tags = {
      Environment = "dev"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_policy    = "calico"
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags = var.tags
}
