#!/bin/bash
set -e

echo "========================================="
echo "  IoT Bonus - Installing required tools"
echo "========================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error()  { echo -e "${RED}[✗]${NC} $1"; }

# ─────────────────────────────────────────────
# 1. Docker
# ─────────────────────────────────────────────
if command -v docker &> /dev/null; then
    print_status "Docker already installed: $(docker --version)"
else
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    print_status "Docker installed: $(docker --version)"
fi

if ! sudo systemctl is-active --quiet docker; then
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# ─────────────────────────────────────────────
# 2. kubectl
# ─────────────────────────────────────────────
if command -v kubectl &> /dev/null; then
    print_status "kubectl already installed"
else
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
    print_status "kubectl installed"
fi

# ─────────────────────────────────────────────
# 3. K3d
# ─────────────────────────────────────────────
if command -v k3d &> /dev/null; then
    print_status "K3d already installed"
else
    echo "Installing K3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    print_status "K3d installed"
fi

# ─────────────────────────────────────────────
# 4. Argo CD CLI
# ─────────────────────────────────────────────
if command -v argocd &> /dev/null; then
    print_status "Argo CD CLI already installed"
else
    echo "Installing Argo CD CLI..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm -f argocd-linux-amd64
    print_status "Argo CD CLI installed"
fi

# ─────────────────────────────────────────────
# 5. Helm
# ─────────────────────────────────────────────
if command -v helm &> /dev/null; then
    print_status "Helm already installed: $(helm version --short)"
else
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    print_status "Helm installed: $(helm version --short)"
fi

echo ""
echo "========================================="
echo "  All tools installed successfully!"
echo "========================================="
