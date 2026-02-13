output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.aks_demo_rg.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration file content"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "node_resource_group" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "identity_principal_id" {
  description = "Principal ID of the system assigned identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  sensitive   = true
}
# ACR Outputs
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "image_full_path" {
  description = "Full path to the Docker image in ACR"
  value       = "${azurerm_container_registry.acr.login_server}/${var.repo_name}:${var.image_tag}"
}

output "image_verification" {
  description = "Image verification status"
  value       = data.external.verify_image.result
  sensitive   = false
}
