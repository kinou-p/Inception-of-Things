#!/bin/bash
set -e

echo "========================================="
echo "  IoT Bonus - K3d + Gitlab + Argo CD"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info()   { echo -e "${CYAN}[i]${NC} $1"; }
print_warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()  { echo -e "${RED}[✗]${NC} $1"; }

CLUSTER_NAME="iot-bonus"
ARGOCD_NS="argocd"
DEV_NS="dev"
GITLAB_NS="gitlab"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$(cd "$SCRIPT_DIR/../confs" && pwd)"

# Gitlab config
GITLAB_HOST="gitlab.local"
GITLAB_ROOT_PASSWORD="iot-bonus-42"
GITLAB_REPO_NAME="iot-app"

# ─────────────────────────────────────────────
# 1. Cleanup existing cluster
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
    -p "8080:8080@loadbalancer" \
    -p "8443:443@loadbalancer" \
    --wait

kubectl wait --for=condition=Ready nodes --all --timeout=120s
print_status "K3d cluster '$CLUSTER_NAME' created and ready"

# ─────────────────────────────────────────────
# 3. Create namespaces
# ─────────────────────────────────────────────
echo ""
print_info "Creating namespaces..."
kubectl create namespace "$ARGOCD_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$DEV_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$GITLAB_NS" --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespaces '$ARGOCD_NS', '$DEV_NS', '$GITLAB_NS' created"

# ─────────────────────────────────────────────
# 4. Install Gitlab via Helm
# ─────────────────────────────────────────────
echo ""
print_info "Adding Gitlab Helm repository..."
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update

print_info "Installing Gitlab (this may take several minutes)..."
helm upgrade --install gitlab gitlab/gitlab \
    --namespace "$GITLAB_NS" \
    --values "$CONFS_DIR/gitlab/values.yaml" \
    --set global.hosts.domain="$GITLAB_HOST" \
    --set global.initialRootPassword.key=password \
    --set global.initialRootPassword.secret=gitlab-initial-root-password \
    --timeout 600s \
    --wait=false

# Create the root password secret
kubectl create secret generic gitlab-initial-root-password \
    --namespace "$GITLAB_NS" \
    --from-literal=password="$GITLAB_ROOT_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

print_info "Waiting for Gitlab webservice to be ready (this can take 5-10 minutes)..."
# Wait for Gitlab webservice deployment
for i in $(seq 1 60); do
    READY=$(kubectl get pods -n "$GITLAB_NS" -l app=webservice 2>/dev/null | grep -c "Running" || true)
    if [ "$READY" -ge 1 ]; then
        print_status "Gitlab webservice is running"
        break
    fi
    if [ "$i" -eq 60 ]; then
        print_warn "Gitlab webservice still not ready after 10 minutes"
        print_warn "It may still be starting. You can check with: kubectl get pods -n $GITLAB_NS"
    fi
    echo "  Waiting for Gitlab... ($i/60)"
    sleep 10
done

# ─────────────────────────────────────────────
# 5. Configure Gitlab - Create project and push app manifests
# ─────────────────────────────────────────────
echo ""
print_info "Setting up Gitlab access..."

# Port-forward Gitlab for API access
kubectl port-forward svc/gitlab-webservice-default -n "$GITLAB_NS" 8181:8181 &>/dev/null &
GITLAB_PF_PID=$!
sleep 5

# Get the Gitlab URL (internal)
GITLAB_SVC="http://gitlab-webservice-default.$GITLAB_NS.svc.cluster.local:8181"
GITLAB_LOCAL="http://localhost:8181"

print_info "Creating Gitlab project '$GITLAB_REPO_NAME'..."

# Create a personal access token first
for i in $(seq 1 10); do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$GITLAB_LOCAL/api/v4/version" 2>/dev/null || true)
    if [ "$RESPONSE" = "200" ]; then
        break
    fi
    echo "  Waiting for Gitlab API... ($i/10)"
    sleep 10
done

# Create project via Gitlab API
curl -s -X POST "$GITLAB_LOCAL/api/v4/projects" \
    -H "Content-Type: application/json" \
    --user "root:$GITLAB_ROOT_PASSWORD" \
    -d "{
        \"name\": \"$GITLAB_REPO_NAME\",
        \"visibility\": \"public\",
        \"initialize_with_readme\": true
    }" > /dev/null 2>&1 && print_status "Gitlab project created" || print_warn "Project may already exist"

# Push deployment manifests to Gitlab
print_info "Pushing app manifests to Gitlab repository..."

TMPDIR=$(mktemp -d)
cd "$TMPDIR"
git init
git remote add origin "http://root:$GITLAB_ROOT_PASSWORD@localhost:8181/root/$GITLAB_REPO_NAME.git"

# Copy app manifests
cp "$CONFS_DIR/dev/deployment.yaml" .
cp "$CONFS_DIR/dev/service.yaml" .

git add .
git commit -m "Initial deployment - v1"
git push -u origin master --force 2>/dev/null || git push -u origin main --force 2>/dev/null
cd -
rm -rf "$TMPDIR"
print_status "App manifests pushed to Gitlab"

# Kill Gitlab port-forward (we don't need it locally anymore)
kill $GITLAB_PF_PID 2>/dev/null || true

# ─────────────────────────────────────────────
# 6. Install Argo CD
# ─────────────────────────────────────────────
echo ""
print_info "Installing Argo CD in namespace '$ARGOCD_NS'..."
kubectl apply -n "$ARGOCD_NS" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_info "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=Available deployment/argocd-server -n "$ARGOCD_NS" --timeout=300s
kubectl wait --for=condition=Available deployment/argocd-repo-server -n "$ARGOCD_NS" --timeout=300s
print_status "Argo CD is ready"

# ─────────────────────────────────────────────
# 7. Configure ArgoCD to use local Gitlab
# ─────────────────────────────────────────────
echo ""
print_info "Configuring Argo CD application with local Gitlab..."

# Create the ArgoCD application pointing to the local Gitlab repo
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wil-playground
  namespace: $ARGOCD_NS
spec:
  project: default
  source:
    repoURL: $GITLAB_SVC/root/$GITLAB_REPO_NAME.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: $DEV_NS
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
EOF

print_status "Argo CD Application configured with local Gitlab"

# ─────────────────────────────────────────────
# 8. Wait for app sync
# ─────────────────────────────────────────────
echo ""
print_info "Waiting for Argo CD to sync the application..."
for i in $(seq 1 30); do
    if kubectl get deployment -n "$DEV_NS" wil-playground &>/dev/null; then
        print_status "Application deployed in '$DEV_NS' namespace"
        break
    fi
    echo "  Waiting for sync... ($i/30)"
    sleep 5
done

kubectl wait --for=condition=Ready pod -l app=wil-playground -n "$DEV_NS" --timeout=120s 2>/dev/null && \
    print_status "Application pod is running" || \
    print_warn "Pod may still be starting"

# ─────────────────────────────────────────────
# 9. Port-forwards
# ─────────────────────────────────────────────
echo ""
print_info "Starting port-forwards..."
kubectl port-forward svc/argocd-server -n "$ARGOCD_NS" 8080:443 &>/dev/null &
ARGOCD_PF_PID=$!
kubectl port-forward svc/wil-playground -n "$DEV_NS" 8888:8888 &>/dev/null &
APP_PF_PID=$!
kubectl port-forward svc/gitlab-webservice-default -n "$GITLAB_NS" 8181:8181 &>/dev/null &
GITLAB_PF2_PID=$!
sleep 2

# ─────────────────────────────────────────────
# 10. Get credentials
# ─────────────────────────────────────────────
ARGOCD_PASSWORD=$(kubectl -n "$ARGOCD_NS" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "========================================="
echo -e "  ${GREEN}Bonus setup complete!${NC}"
echo "========================================="
echo ""
echo "  Gitlab:"
echo "    URL:      http://localhost:8181"
echo "    User:     root"
echo "    Password: $GITLAB_ROOT_PASSWORD"
echo ""
echo "  Argo CD Dashboard:"
echo "    URL:      https://localhost:8080"
echo "    User:     admin"
echo "    Password: $ARGOCD_PASSWORD"
echo ""
echo "  Application:"
echo "    URL:      http://localhost:8888"
echo ""
echo "  Namespaces:"
echo "    kubectl get ns"
echo "    kubectl get pods -n $ARGOCD_NS"
echo "    kubectl get pods -n $DEV_NS"
echo "    kubectl get pods -n $GITLAB_NS"
echo ""
echo "  To change app version (v1 -> v2):"
echo "    1. Clone from Gitlab:"
echo "       git clone http://root:$GITLAB_ROOT_PASSWORD@localhost:8181/root/$GITLAB_REPO_NAME.git"
echo "    2. Edit deployment.yaml: change v1 to v2"
echo "    3. git add . && git commit -m 'v2' && git push"
echo "    4. ArgoCD will auto-sync the change"
echo "    5. curl http://localhost:8888/"
echo ""
echo "  Port-forward PIDs:"
echo "    ArgoCD=$ARGOCD_PF_PID App=$APP_PF_PID Gitlab=$GITLAB_PF2_PID"
echo "========================================="
