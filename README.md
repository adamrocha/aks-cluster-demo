# AKS Cluster Demo

This repository contains Terraform configuration for deploying an Azure Kubernetes Service (AKS) cluster with starter infrastructure code.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An active Azure subscription

## Azure Authentication

Before running Terraform, authenticate with Azure:

```bash
az login
```

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` to customize your deployment:
   - Resource group name and location
   - Cluster name and Kubernetes version
   - Node pool configuration (size, count, auto-scaling)
   - Network settings
   - Tags

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan the Deployment

```bash
terraform plan
```

### Apply the Configuration

```bash
terraform apply
```

### Get Cluster Credentials

After the cluster is created, configure kubectl:

```bash
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
```

### Verify the Cluster

```bash
kubectl get nodes
kubectl cluster-info
```

### Destroy the Infrastructure

When you're done, clean up resources:

```bash
terraform destroy
```

## Infrastructure Components

### Resources Created

- **Resource Group**: Container for all AKS resources
- **AKS Cluster**: Managed Kubernetes cluster with:
  - System-assigned managed identity
  - Auto-scaling node pool (optional)
  - Network plugin (kubenet or azure)
  - Network policy (calico)

### Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `resource_group_name` | Name of the resource group | `aks-demo-rg` |
| `location` | Azure region | `East US` |
| `cluster_name` | Name of the AKS cluster | `aks-demo-cluster` |
| `kubernetes_version` | Kubernetes version | `1.27.7` |
| `node_count` | Number of nodes | `2` |
| `vm_size` | VM size for nodes | `Standard_D2s_v3` |
| `enable_auto_scaling` | Enable auto-scaling | `true` |
| `min_count` | Minimum nodes (auto-scaling) | `1` |
| `max_count` | Maximum nodes (auto-scaling) | `5` |

See `variables.tf` for the complete list of configurable parameters.

### Outputs

After deployment, Terraform outputs:

- `resource_group_name`: Name of the resource group
- `cluster_name`: Name of the AKS cluster
- `cluster_id`: Full Azure resource ID
- `cluster_fqdn`: Cluster FQDN
- `node_resource_group`: Auto-generated resource group for cluster resources
- `identity_principal_id`: Principal ID of the managed identity

## Security Considerations

- The `kube_config` output is marked as sensitive and won't be displayed in logs
- The `terraform.tfvars` file is excluded from version control (see `.gitignore`)
- The cluster uses a system-assigned managed identity for authentication
- Network policies are enabled by default for pod-to-pod traffic control

## Customization

You can customize the cluster by modifying variables in `terraform.tfvars` or by passing them via command line:

```bash
terraform apply -var="node_count=3" -var="vm_size=Standard_D4s_v3"
```

## Additional Resources

- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
