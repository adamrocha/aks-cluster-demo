variable "resource_group" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-demo-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-cluster-demo"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aks-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34.1"
}

variable "node_pool" {
  description = "Name of the default node pool"
  type        = string
  default     = "nodepool"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the VMs in the node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "auto_scaling_enabled" {
  description = "Enable auto-scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "network_plugin" {
  description = "Network plugin to use (azure or kubenet)"
  type        = string
  default     = "kubenet"
}

variable "network_policy" {
  description = "Network policy to use"
  type        = string
  default     = "calico"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# Azure Container Registry Variables
variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)"
  type        = string
  default     = "aksdemoacr2026"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium"
  }
}

variable "acr_georeplications" {
  description = "List of Azure regions for ACR geo-replication (Premium SKU only)"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = []
}

variable "repo_name" {
  description = "Name of the container repository"
  type        = string
  default     = "hello-world-demo"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "v1.0.0"
}

variable "platforms" {
  description = "Target platforms for multi-arch image build"
  type        = list(string)
  default     = ["linux/amd64", "linux/arm64"]
}

