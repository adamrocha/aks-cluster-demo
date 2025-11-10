# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = "aks-demo-rg"
  location = "West US 2"

  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  # checkov:skip=CKV_AZURE_170: Will switch to "Standard" SKU when EncryptionAtHost is enabled
  # checkov:skip=CKV_AZURE_227: Subscription does not enable EncryptionAtHost
  name                      = "aks-cluster-demo"
  location                  = "West US 2"
  resource_group_name       = azurerm_resource_group.aks.name
  dns_prefix                = "aksdemo"
  kubernetes_version        = "1.31.11"
  local_account_disabled    = false
  private_cluster_enabled   = true
  automatic_upgrade_channel = "stable"
  sku_tier                  = "Free"

  default_node_pool {
    name                         = "default"
    vm_size                      = "Standard_B2s"
    auto_scaling_enabled         = true
    min_count                    = 1
    max_count                    = 5
    max_pods                     = 50
    os_disk_type                 = "Ephemeral"
    host_encryption_enabled      = false
    os_disk_size_gb              = 30
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
