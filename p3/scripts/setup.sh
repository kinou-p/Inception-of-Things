#!/bin/bash
set -e

echo "========================================="
echo "  IoT P3 - Setting up K3d + Argo CD"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info()   { echo -e "${CYAN}[i]${NC} $1"; }
print_warn()   { echo -e "${YELLOW}[!]${NC} $1"; }

CLUSTER_NAME="iot"
ARGOCD_NS="argocd"
DEV_NS="dev"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$(cd "$SCRIPT_DIR/../confs" && pwd)"

# ─────────────────────────────────────────────
# 1. Delete existing cluster if present
# ─────────────────────────────────────────────
if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    print_warn "Cluster '$CLUSTER_NAME' already exists, deleting..."
    k3d cluster delete "$CLUSTER_NAME"
fi

# ─────────────────────────────────────────────
# 2. Create K3d cluster
# ─────────────────────────────────────────────
echo ""
print_info "Creating K3d cluster '$CLUSTER_NAME'..."
k3d cluster create "$CLUSTER_NAME" \
    --api-port 6443 \
    -p "8888:8888@loadbalancer" \
    --wait
print_status "K3d cluster '$CLUSTER_NAME' created"

# Wait for cluster to be ready
kubectl wait --for=condition=Ready nodes --all --timeout=120s
print_status "Cluster nodes are ready"

# ─────────────────────────────────────────────
# 3. Create namespaces
# ─────────────────────────────────────────────
echo ""
print_info "Creating namespaces..."
kubectl create namespace "$ARGOCD_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$DEV_NS" --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespaces '$ARGOCD_NS' and '$DEV_NS' created"

# ─────────────────────────────────────────────
# 4. Install Argo CD
# ─────────────────────────────────────────────
echo ""
print_info "Installing Argo CD in namespace '$ARGOCD_NS'..."
kubectl apply -n "$ARGOCD_NS" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
print_status "Argo CD manifests applied"

# Wait for Argo CD to be ready
print_info "Waiting for Argo CD pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=Available deployment/argocd-server -n "$ARGOCD_NS" --timeout=300s
kubectl wait --for=condition=Available deployment/argocd-repo-server -n "$ARGOCD_NS" --timeout=300s
kubectl wait --for=condition=Available deployment/argocd-redis -n "$ARGOCD_NS" --timeout=300s
print_status "Argo CD is ready"

# ─────────────────────────────────────────────
# 5. Configure Argo CD Application
# ─────────────────────────────────────────────
echo ""
print_info "Deploying Argo CD Application..."
kubectl apply -f "$CONFS_DIR/argocd/application.yaml"
print_status "Argo CD Application configured"

# ─────────────────────────────────────────────
# 6. Get Argo CD admin password
# ─────────────────────────────────────────────
echo ""
print_info "Retrieving Argo CD admin credentials..."
ARGOCD_PASSWORD=$(kubectl -n "$ARGOCD_NS" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# ─────────────────────────────────────────────
# 7. Port-forward Argo CD (background)
# ─────────────────────────────────────────────
echo ""
print_info "Starting Argo CD port-forward on localhost:8080..."
kubectl port-forward svc/argocd-server -n "$ARGOCD_NS" 8080:443 &>/dev/null &
ARGOCD_PF_PID=$!
sleep 2

# ─────────────────────────────────────────────
# 8. Wait for the app to sync
# ─────────────────────────────────────────────
echo ""
print_info "Waiting for Argo CD to sync the application..."
sleep 10

# Check if the deployment exists in dev namespace
for i in $(seq 1 30); do
    if kubectl get deployment -n "$DEV_NS" wil-playground &>/dev/null; then
        print_status "Application deployed in '$DEV_NS' namespace"
        break
    fi
    echo "  Waiting for sync... ($i/30)"
    sleep 5
done

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod -l app=wil-playground -n "$DEV_NS" --timeout=120s 2>/dev/null && \
    print_status "Application pod is running" || \
    print_warn "Pod may still be starting up"

# ─────────────────────────────────────────────
# 9. Port-forward the app (background)
# ─────────────────────────────────────────────
kubectl port-forward svc/wil-playground -n "$DEV_NS" 8888:8888 &>/dev/null &
APP_PF_PID=$!
sleep 2

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "========================================="
echo -e "  ${GREEN}Setup complete!${NC}"
echo "========================================="
echo ""
echo "  Argo CD Dashboard:"
echo "    URL:      https://localhost:8080"
echo "    User:     admin"
echo "    Password: $ARGOCD_PASSWORD"
echo ""
echo "  Application:"
echo "    URL:      http://localhost:8888"
echo ""
echo "  Useful commands:"
echo "    kubectl get ns"
echo "    kubectl get pods -n $ARGOCD_NS"
echo "    kubectl get pods -n $DEV_NS"
echo "    curl http://localhost:8888/"
echo ""
echo "  To change app version (v1 -> v2):"
echo "    Edit p3/confs/dev/deployment.yaml"
echo "    Change wil42/playground:v1 to wil42/playground:v2"
echo "    git add . && git commit -m 'v2' && git push"
echo "    Argo CD will auto-sync the change"
echo ""
echo "  Port-forward PIDs: ArgoCD=$ARGOCD_PF_PID, App=$APP_PF_PID"
echo "  To stop: kill $ARGOCD_PF_PID $APP_PF_PID"
echo "========================================="
