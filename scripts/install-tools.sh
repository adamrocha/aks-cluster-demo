#!/bin/bash
set -e

echo "🔧 Installing Required Tools for AKS Cluster Demo"
echo ""

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "🖥️  Detected OS: $OS ($ARCH)"
echo ""

# Install Azure CLI
if ! command -v az &> /dev/null; then
    echo "📦 Installing Azure CLI..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install azure-cli
    elif [[ "$OS" == "Linux" ]]; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
    echo "✅ Azure CLI installed"
else
    echo "✅ Azure CLI already installed ($(az version --output tsv --query \"azure-cli\"))"
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing kubectl..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install kubectl
    elif [[ "$OS" == "Linux" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi
    echo "✅ kubectl installed"
else
    echo "✅ kubectl already installed ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
fi

# Install Terraform
if ! command -v terraform &> /dev/null; then
    echo "📦 Installing Terraform..."
    if [[ "$OS" == "Darwin" ]]; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    elif [[ "$OS" == "Linux" ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi
    echo "✅ Terraform installed"
else
    echo "✅ Terraform already installed ($(terraform version | head -n1))"
fi

# Install jq
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install jq
    elif [[ "$OS" == "Linux" ]]; then
        sudo apt-get update && sudo apt-get install -y jq
    fi
    echo "✅ jq installed"
else
    echo "✅ jq already installed ($(jq --version))"
fi

# Install helm (optional)
if ! command -v helm &> /dev/null; then
    echo "📦 Installing Helm..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install helm
    elif [[ "$OS" == "Linux" ]]; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    echo "✅ Helm installed"
else
    echo "✅ Helm already installed ($(helm version --short))"
fi

# Install kubelogin for AKS
if ! command -v kubelogin &> /dev/null; then
    echo "📦 Installing kubelogin (Azure Kubernetes Service authentication)..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install Azure/kubelogin/kubelogin
    elif [[ "$OS" == "Linux" ]]; then
        wget https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
        unzip kubelogin-linux-amd64.zip
        sudo mv bin/linux_amd64/kubelogin /usr/local/bin/
        rm -rf bin kubelogin-linux-amd64.zip
    fi
    echo "✅ kubelogin installed"
else
    echo "✅ kubelogin already installed"
fi

echo ""
echo "✅ All tools installed successfully!"
echo ""
echo "📝 Next steps:"
echo "  1. Authenticate to Azure: az login"
echo "  2. Set your subscription: az account set --subscription <subscription-id>"
echo "  3. Run: make tf-bootstrap"
