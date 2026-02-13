# aks-cluster-demo

## Overview

This project provides an example of deploying and managing an Azure Kubernetes Service (AKS) cluster using Infrastructure as Code (IaC) tools with a hybrid approach: Terraform manages infrastructure while Kubernetes manifests manage application deployments.

## Features

- **Automated AKS cluster provisioning** with Terraform
- **Kubernetes manifest-based deployments** for applications
- **Blue/Green deployment pattern** for zero-downtime releases
- **Security-hardened configurations** with Azure best practices
- **Kustomize support** for environment-specific configurations
- **Validation tools** for manifests before deployment
- **Helper scripts** for common operations
- **Azure Monitor integration** for logging and monitoring

## Prerequisites

- Azure account with appropriate permissions
- [Terraform](https://www.terraform.io/) (v1.0+)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (configured with credentials)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [jq](https://stedolan.github.io/jq/) (for script operations)
- [helm](https://helm.sh/) (optional, for Prometheus, Grafana stacks)
- [kubelogin](https://github.com/Azure/kubelogin) (for AKS authentication)

## Quick Start

### Option 1: Automated Setup with Makefile

1. **Clone the repository:**

```sh
git clone https://github.com/your-org/aks-cluster-demo.git
cd aks-cluster-demo
```

1. **Install required tools:**

```sh
make install-tools
```

1. **Configure Azure credentials:**

```sh
az login
```

1. **Create the AKS cluster:**

```sh
make tf-bootstrap
make tf-apply
```

1. **Access the cluster:**

```sh
kubectl get nodes
```

### Option 2: Manual Setup

1. **Clone the repository:**

```sh
git clone https://github.com/your-org/aks-cluster-demo.git
cd aks-cluster-demo
```

1. **Configure Azure credentials:**

```sh
az login
```

1. **Initialize Terraform:**

```sh
cd terraform
terraform init
terraform plan
terraform apply
```

1. **Update kubeconfig:**

```sh
az aks get-credentials --resource-group aks-cluster-demo-rg --name aks-cluster-demo
```

## Quick Reference

### Terraform Commands

```sh
make tf-bootstrap     # Initialize and validate Terraform
make tf-plan          # Preview infrastructure changes
make tf-apply         # Apply infrastructure changes
make tf-destroy       # Destroy all infrastructure (with confirmation)
make tf-output        # Display Terraform outputs
make tf-state         # List Terraform state resources
```

### Kubernetes Manifest Commands

```sh
make k8s-validate         # Validate manifests (client-side)
make k8s-validate-server  # Validate against cluster (server-side)
make k8s-apply            # Deploy all manifests
make k8s-status           # Check deployment status
make k8s-logs             # View application logs
make k8s-describe         # Describe deployment details
make k8s-restart          # Restart deployment
make k8s-delete           # Delete all manifests (with confirmation)
```

### Kustomize Commands

```sh
make k8s-kustomize-validate # Validate kustomize configuration
make k8s-kustomize-apply    # Deploy with kustomize
make k8s-kustomize-diff     # Preview changes
make k8s-kustomize-delete   # Delete resources
```

### Blue/Green Deployment Commands

```sh
make bg-deploy        # Deploy blue/green infrastructure
make bg-status        # Show blue/green deployment status
make bg-switch-blue   # Switch traffic to blue version
make bg-switch-green  # Switch traffic to green version
make bg-rollback      # Rollback to previous version
make bg-cleanup       # Delete blue/green resources
```

### Utility Commands

```sh
make help          # Show all available commands
make check-azure   # Verify Azure credentials
make install-tools # Install required tools
```

## Deployment Strategies

This project supports multiple deployment strategies to fit different use cases:

### 1. Rolling Update (Default)

Located in `manifests/` directory. Best for:

- Development environments
- Simple updates with backward compatibility
- Resource-constrained environments

```sh
make k8s-apply          # Deploy with rolling updates
make k8s-restart        # Restart deployment
```

### 2. Blue/Green Deployment

Located in `manifests/blue-green/` directory. Best for:

- Production environments
- Zero-downtime deployments
- Quick rollback capability
- Major version changes

```sh
# Deploy blue/green infrastructure
make bg-deploy

# Check status
make bg-status

# Switch to new version (green)
make bg-switch-green

# Instant rollback if needed
make bg-rollback
```

**Key Benefits:**

- **Zero Downtime** - Traffic switches instantly between versions
- **Fast Rollback** - Revert to previous version in seconds
- **Full Testing** - Test new version before exposing to users
- **Reduced Risk** - Both versions run simultaneously

## Project Structure

```text
aks-cluster-demo/
├── Makefile                                    # Build automation and task runner
├── README.md                                   # This file
├── terraform.tfvars.example                    # Example Terraform variables
├── manifests/                                  # Kubernetes YAML manifests
│   ├── hello-world-ns.yaml                     # Namespace definition
│   ├── hello-world-deployment.yaml             # Deployment with security hardening
│   ├── hello-world-service.yaml                # LoadBalancer service
│   ├── kustomization.yaml                      # Kustomize configuration
│   └── blue-green/                             # Blue/Green deployment manifests
│       ├── hello-world-ns.yaml                 # Namespace for blue/green
│       ├── hello-world-deployment-blue.yaml    # Blue deployment
│       ├── hello-world-deployment-green.yaml   # Green deployment
│       ├── hello-world-service.yaml            # Service with version selector
│       └── kustomization.yaml                  # Kustomize for blue/green
├── scripts/                                    # Automation scripts
│   ├── blue-green-switch.sh                    # Blue/Green deployment switcher
│   ├── fetch-billing-total.sh                  # Azure cost report
│   ├── install-tools.sh                        # Install required tools
│   └── update-kubeconfig.sh                    # Update kubectl config
└── terraform/                                  # Infrastructure as Code
    ├── main.tf                                 # Main Terraform configuration
    ├── outputs.tf                              # Output values
    ├── providers.tf                            # Azure provider configuration
    ├── variables.tf                            # Input variables
    └── versions.tf                             # Provider version constraints
```

## Security Features

- **Azure RBAC** - Role-based access control for AKS
- **Network Security Groups** - Limited to AKS VNet only
- **Managed Identity** - For secure Azure resource access
- **Azure Monitor** - Logging and monitoring integration
- **Image scanning** - Automated container vulnerability scanning
- **Resource limits** - Container security hardening
- **Security contexts** - Drop all capabilities, seccomp profiles

## Monitoring and Logging

- **Azure Monitor** - Metrics collection and alerting
- **Container Insights** - Container-level monitoring
- **Log Analytics** - Centralized logging
- **Azure Network Watcher** - Network traffic analysis

## Troubleshooting

**Pods not starting:**

```sh
kubectl describe pod <pod-name> -n hello-world-ns
kubectl logs <pod-name> -n hello-world-ns
```

**LoadBalancer not provisioning:**

```sh
kubectl describe service hello-world-service -n hello-world-ns
# Check Azure Load Balancer in portal
```

**Authentication issues:**

```sh
az aks get-credentials --resource-group aks-cluster-demo-rg --name aks-cluster-demo
kubelogin convert-kubeconfig -l azurecli
```

**Terraform state issues:**

```sh
# Check backend configuration
az storage container list --account-name tfstateakscluster --auth-mode login
```

## Cleanup

To delete all resources:

```sh
# Recommended: Delete K8s resources first, then infrastructure
make tf-destroy

# This will:
# 1. Prompt for K8s resource deletion confirmation
# 2. Delete manifests (services, deployments, namespaces)
# 3. Prompt for Terraform infrastructure deletion confirmation
# 4. Destroy AKS cluster, VNet, and all Azure resources
```

**Note:** The destroy process includes confirmations to prevent accidental deletions.

## Cost Optimization

- **Auto-scaling** - Scale down during off-hours
- **Check billing:** `./scripts/fetch-billing-total.sh`
- **Delete unused resources:** Regularly run `make tf-destroy` for dev/test environments
- **Right-size nodes:** Default is `Standard_D2s_v3` (cost-effective)

## Common Issues

## Issue: kubectl access denied

```sh
# Solution: Update kubeconfig with admin credentials
az aks get-credentials --resource-group aks-cluster-demo-rg --name aks-cluster-demo --admin
```

## Issue: Cannot connect to cluster

```sh
# Solution: Verify network access and update kubeconfig
./scripts/update-kubeconfig.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Validate with `make k8s-validate` and `terraform validate`
5. Test the deployment
6. Submit a pull request

## License

This project is provided as-is for educational and demonstration purposes.

## Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
