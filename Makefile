export AZURE_PAGER :=
SHELL := /bin/bash
STORAGE_ACCOUNT=tfstateakscluster
CONTAINER_NAME=tfstate
RESOURCE_GROUP=aks-cluster-demo-rg
LOCATION=eastus
TF_DIR=terraform

.PHONY: check-azure help

.DEFAULT_GOAL := help

help:
	@echo "📚 AKS Cluster Demo - Available Commands"
	@echo ""
	@echo "🔧 Terraform Commands:"
	@echo "  make tf-bootstrap        - Initialize and validate Terraform"
	@echo "  make tf-storage          - Create Azure Storage for state"
	@echo "  make tf-init             - Initialize Terraform"
	@echo "  make tf-validate         - Validate Terraform configuration"
	@echo "  make tf-plan             - Preview infrastructure changes"
	@echo "  make tf-apply            - Apply infrastructure changes"
	@echo "  make tf-destroy          - Destroy all infrastructure"
	@echo "  make tf-destroy-clean    - Delete K8s resources, LBs, NSGs, then destroy"
	@echo "  make tf-output           - Display Terraform outputs"
	@echo "  make tf-state            - List Terraform state"
	@echo ""
	@echo "☸️  Kubernetes Manifest Commands:"
	@echo "  make k8s-validate        - Validate manifests (client-side)"
	@echo "  make k8s-validate-server - Validate against cluster (server-side)"
	@echo "  make k8s-apply           - Deploy all manifests"
	@echo "  make k8s-status          - Check deployment status"
	@echo "  make k8s-logs            - View application logs"
	@echo "  make k8s-shell           - Open shell in running container"
	@echo "  make k8s-describe        - Describe deployment"
	@echo "  make k8s-restart         - Restart deployment"
	@echo "  make k8s-delete          - Delete all manifests"
	@echo ""
	@echo "🎨 Kustomize Commands:"
	@echo "  make k8s-kustomize-validate - Validate kustomize config"
	@echo "  make k8s-kustomize-apply    - Deploy with kustomize"
	@echo "  make k8s-kustomize-diff     - Preview changes"
	@echo "  make k8s-kustomize-delete   - Delete resources"
	@echo ""
	@echo "� Docker/ACR Commands:"
	@echo "  make docker-build        - Build and push image to ACR"
	@echo "  make docker-login        - Login to ACR"
	@echo "  make docker-list         - List images in ACR"
	@echo ""
	@echo "�🔵🟢 Blue/Green Deployment Commands:"
	@echo "  make bg-deploy           - Deploy blue/green infrastructure"
	@echo "  make bg-status           - Show blue/green status"
	@echo "  make bg-switch-blue      - Switch traffic to blue"
	@echo "  make bg-switch-green     - Switch traffic to green"
	@echo "  make bg-rollback         - Rollback to previous version"
	@echo "  make bg-cleanup          - Delete blue/green resources"
	@echo ""
	@echo "🛠️  Utility Commands:"
	@echo "  make install-tools       - Install required tools"
	@echo "  make check-azure         - Verify Azure credentials"
	@echo "  make update-kubeconfig   - Update kubectl config for AKS cluster"
	@echo "  make help                - Show this help message"
	@echo ""

check-azure:
	@echo "🔍 Checking Azure credentials..."
	@if ! az account show > /dev/null 2>&1; then \
		echo "⚠️  Azure CLI not authenticated. Running az login..."; \
		az login; \
	else \
		echo "✅ Azure credentials valid."; \
	fi

install-tools:
	@echo "🚀 Running install-tools script..."
	@/bin/bash ./scripts/install-tools.sh

update-kubeconfig:
	@echo "🔧 Updating kubeconfig..."
	@/bin/bash ./scripts/update-kubeconfig.sh

# Docker/ACR Commands
docker-build:
	@echo "🐳 Building and pushing image to ACR..."
	@/bin/bash ./scripts/docker-image.sh

docker-login:
	@echo "🔐 Logging in to ACR..."
	@ACR_NAME=$$(terraform -chdir=$(TF_DIR) output -raw acr_name 2>/dev/null || echo "aksdemoacr2026"); \
	az acr login --name "$$ACR_NAME"

docker-list:
	@echo "📋 Listing images in ACR..."
	@ACR_NAME=$$(terraform -chdir=$(TF_DIR) output -raw acr_name 2>/dev/null || echo "aksdemoacr2026"); \
	REPO_NAME=$$(echo "hello-world-demo"); \
	echo "Container Registry: $$ACR_NAME"; \
	echo ""; \
	echo "Repositories:"; \
	az acr repository list --name "$$ACR_NAME" --output table; \
	echo ""; \
	if az acr repository show-tags --name "$$ACR_NAME" --repository "$$REPO_NAME" --output table 2>/dev/null; then \
		echo ""; \
	else \
		echo "No tags found for $$REPO_NAME (repository may not exist yet)"; \
	fi

tf-bootstrap: tf-storage tf-format tf-init tf-validate tf-plan
	@echo "🔄 Running Terraform bootstrap..."
	@echo "✅ Terraform tasks completed successfully."
	@echo "🚀 To apply changes, run 'make tf-apply'."

tf-storage: check-azure
	@echo "🔍 Checking Resource Group: $(RESOURCE_GROUP)"
	@if ! az group show --name "$(RESOURCE_GROUP)" > /dev/null 2>&1; then \
		echo "🚀 Creating resource group $(RESOURCE_GROUP)..."; \
		az group create --name "$(RESOURCE_GROUP)" --location "$(LOCATION)"; \
	else \
		echo "✅ Resource group $(RESOURCE_GROUP) already exists."; \
	fi
	@echo "🔍 Checking Storage Account: $(STORAGE_ACCOUNT)"
	@if ! az storage account show --name "$(STORAGE_ACCOUNT)" --resource-group "$(RESOURCE_GROUP)" > /dev/null 2>&1; then \
		echo "🚀 Creating storage account $(STORAGE_ACCOUNT)..."; \
		az storage account create \
			--name "$(STORAGE_ACCOUNT)" \
			--resource-group "$(RESOURCE_GROUP)" \
			--location "$(LOCATION)" \
			--sku Standard_LRS \
			--encryption-services blob \
			--https-only true \
			--min-tls-version TLS1_2 \
			--allow-blob-public-access false; \
		echo "✅ Storage account $(STORAGE_ACCOUNT) created."; \
	else \
		echo "✅ Storage account $(STORAGE_ACCOUNT) already exists."; \
	fi
	@echo "🔍 Checking container: $(CONTAINER_NAME)"
	@ACCOUNT_KEY=$$(az storage account keys list --account-name "$(STORAGE_ACCOUNT)" --resource-group "$(RESOURCE_GROUP)" --query '[0].value' -o tsv); \
	if ! az storage container exists \
		--name "$(CONTAINER_NAME)" \
		--account-name "$(STORAGE_ACCOUNT)" \
		--account-key "$$ACCOUNT_KEY" --query exists -o tsv | grep -q true; then \
		echo "🚀 Creating container $(CONTAINER_NAME)..."; \
		az storage container create \
			--name "$(CONTAINER_NAME)" \
			--account-name "$(STORAGE_ACCOUNT)" \
			--account-key "$$ACCOUNT_KEY" \
			--public-access off; \
		echo "✅ Container $(CONTAINER_NAME) created."; \
	else \
		echo "✅ Container $(CONTAINER_NAME) already exists."; \
	fi
	@echo "✅ Storage backend ready for Terraform state."

tf-format:
	terraform -chdir=$(TF_DIR) fmt
	@echo "✅ Terraform files formatted."

tf-init:
	terraform -chdir=$(TF_DIR) init
	@echo "✅ Terraform initialized."

tf-validate:
	terraform -chdir=$(TF_DIR) validate
	@echo "✅ Terraform configuration validated."

tf-plan:
	terraform -chdir=$(TF_DIR) plan
	@echo "✅ Terraform plan completed."

tf-apply:
	terraform -chdir=$(TF_DIR) apply
	@echo "✅ Terraform resources deployed."

tf-destroy: k8s-delete
	terraform -chdir=$(TF_DIR) destroy 
	@echo "✅ Terraform resources destroyed."

tf-output:
	terraform -chdir=$(TF_DIR) output
	@echo "✅ Terraform outputs displayed."
	@echo "🔍 To view specific output, run 'terraform output <output_name>'."

tf-state:
	terraform -chdir=$(TF_DIR) state list
	@echo "✅ Terraform state listed."
	@echo "🔍 To view specific resource, run 'terraform state show <resource_name>'."

# Kubernetes Manifest Deployment Targets
k8s-validate:
	@echo "🔍 Validating Kubernetes manifests..."
	@echo "--- Validating namespace ---"
	kubectl apply --dry-run=client -f manifests/hello-world-ns.yaml
	@echo "--- Validating deployment ---"
	kubectl apply --dry-run=client -f manifests/hello-world-deployment.yaml
	@echo "--- Validating service ---"
	kubectl apply --dry-run=client -f manifests/hello-world-service.yaml
	@echo "✅ All manifests are valid."

k8s-validate-server:
	@echo "🔍 Validating manifests against cluster (server-side)..."
	@echo "--- Validating namespace ---"
	kubectl apply --dry-run=server -f manifests/hello-world-ns.yaml
	@echo "--- Validating deployment ---"
	kubectl apply --dry-run=server -f manifests/hello-world-deployment.yaml
	@echo "--- Validating service ---"
	kubectl apply --dry-run=server -f manifests/hello-world-service.yaml
	@echo "✅ All manifests are valid against cluster."

k8s-apply-ns:
	@echo "🚀 Creating namespace..."
	kubectl apply -f manifests/hello-world-ns.yaml
	@echo "✅ Namespace created."

k8s-apply: k8s-apply-ns
	@echo "🚀 Deploying Kubernetes manifests..."
	kubectl apply -f manifests/hello-world-deployment.yaml
	kubectl apply -f manifests/hello-world-service.yaml
	@echo "✅ Kubernetes resources deployed."

k8s-delete:
	@echo "⚠️  WARNING: This will delete all Kubernetes resources."
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🗑️  Deleting Kubernetes manifests..."; \
		kubectl delete -f manifests/hello-world-service.yaml --ignore-not-found=true; \
		kubectl delete -f manifests/hello-world-deployment.yaml --ignore-not-found=true; \
		kubectl delete -f manifests/hello-world-ns.yaml --ignore-not-found=true; \
		echo "⏳ Waiting for resources to be fully deleted..."; \
		sleep 30; \
		echo "✅ Kubernetes resources deleted."; \
	else \
		echo "❎ Deletion cancelled."; \
	fi

k8s-undo:
	@echo "🔄 Undoing last applied Kubernetes manifests..."
	kubectl rollout undo deployment/hello-world -n hello-world-ns
	@echo "✅ Undo complete."

k8s-status:
	@echo "📊 Checking Kubernetes deployment status..."
	@echo "--- Namespace ---"
	kubectl get namespace hello-world-ns 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "--- Deployments ---"
	kubectl get deployments -n hello-world-ns 2>/dev/null || echo "No deployments found"
	@echo ""
	@echo "--- Pods ---"
	kubectl get pods -n hello-world-ns 2>/dev/null || echo "No pods found"
	@echo ""
	@echo "--- Services ---"
	kubectl get services -n hello-world-ns 2>/dev/null || echo "No services found"
	@echo ""
	@echo "--- LoadBalancer IP ---"
	@kubectl get service hello-world-service -n hello-world-ns -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null && echo "" || echo "LoadBalancer not ready yet"

k8s-logs:
	@echo "📜 Fetching logs from hello-world deployment..."
	kubectl logs -n hello-world-ns -l app=hello-world --tail=100

k8s-shell:
	@echo "🐚 Opening shell in hello-world container..."
	@POD=$$(kubectl get pod -n hello-world-ns -l app=hello-world -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo "❌ No running pods found in hello-world-ns"; \
		exit 1; \
	fi; \
	echo "📦 Connecting to pod: $$POD"; \
	kubectl exec -it -n hello-world-ns $$POD -- sh

k8s-events:
	@echo "📜 Fetching events from hello-world namespace..."
	kubectl get events -n hello-world-ns --sort-by='.metadata.creationTimestamp'

k8s-describe:
	@echo "🔍 Describing hello-world deployment..."
	kubectl describe deployment hello-world -n hello-world-ns

k8s-restart:
	@echo "🔄 Restarting hello-world deployment..."
	kubectl rollout restart deployment/hello-world -n hello-world-ns
	@echo "✅ Deployment restarted."

# Kustomize-based deployment (alternative to direct kubectl apply)
k8s-kustomize-validate:
	@echo "🔍 Validating Kustomize configuration..."
	kubectl apply --dry-run=client -k manifests/
	@echo "✅ Kustomize configuration is valid."

k8s-kustomize-apply:
	@echo "🚀 Deploying with Kustomize..."
	kubectl apply -k manifests/
	@echo "✅ Kubernetes resources deployed via Kustomize."

k8s-kustomize-delete:
	@echo "🗑️  Deleting with Kustomize..."
	kubectl delete -k manifests/ --ignore-not-found=true
	@echo "✅ Kubernetes resources deleted via Kustomize."

k8s-kustomize-diff:
	@echo "🔍 Showing diff with Kustomize..."
	kubectl diff -k manifests/ || true

# Blue/Green Deployment Commands
bg-deploy:
	@echo "🔵🟢 Deploying Blue/Green infrastructure..."
	kubectl apply -k manifests/blue-green/
	@echo ""
	@echo "✅ Blue/Green deployment created. Both blue and green environments are now running."
	@echo "📊 Use 'make bg-status' to check the status"

bg-status:
	@echo "🔵🟢 Blue/Green Deployment Status"
	@./scripts/blue-green-switch.sh status

bg-switch-blue:
	@echo "🔵 Switching traffic to BLUE deployment..."
	@./scripts/blue-green-switch.sh blue

bg-switch-green:
	@echo "🟢 Switching traffic to GREEN deployment..."
	@./scripts/blue-green-switch.sh green

bg-rollback:
	@echo "⏮️  Rolling back to previous deployment..."
	@./scripts/blue-green-switch.sh rollback

bg-cleanup:
	@echo "🗑️  Deleting Blue/Green deployment resources..."
	kubectl delete -k manifests/blue-green/ --ignore-not-found=true
	@echo "✅ Blue/Green resources deleted."

bg-test-blue:
	@echo "🔵 Testing Blue deployment..."
	@POD=$$(kubectl get pod -n hello-world-ns -l version=blue -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo "❌ No blue pods found"; \
		exit 1; \
	fi; \
	echo "Port-forwarding to blue deployment on localhost:8080..."; \
	kubectl port-forward -n hello-world-ns $$POD 8080:8080

bg-test-green:
	@echo "🟢 Testing Green deployment..."
	@POD=$$(kubectl get pod -n hello-world-ns -l version=green -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo "❌ No green pods found"; \
		exit 1; \
	fi; \
	echo "Port-forwarding to green deployment on localhost:8081..."; \
	kubectl port-forward -n hello-world-ns $$POD 8081:8080

bg-logs-blue:
	@echo "📜 Fetching logs from BLUE deployment..."
	kubectl logs -n hello-world-ns -l version=blue --tail=100 -f

bg-logs-green:
	@echo "📜 Fetching logs from GREEN deployment..."
	kubectl logs -n hello-world-ns -l version=green --tail=100 -f