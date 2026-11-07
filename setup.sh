
#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="demo"
IMAGE_NAME="enterprise-bot:1.0"
NAMESPACE="demo"
RELEASE_NAME="demo"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=== Enterprise Bot DevOps Setup ==="

# 1. Create or reuse Kind cluster
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
    echo "Kind cluster '$CLUSTER_NAME' already exists."
else
    echo "Creating Kind cluster '$CLUSTER_NAME'..."

    KIND_CONFIG="$(mktemp)"
    trap 'rm -f "$KIND_CONFIG"' EXIT

    cat > "$KIND_CONFIG" <<'KIND'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    labels:
      ingress-ready: "true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
KIND

    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
    rm -f "$KIND_CONFIG"
    trap - EXIT
fi

kubectl cluster-info --context "kind-$CLUSTER_NAME"

# 2. Install ingress-nginx
echo "Installing ingress-nginx..."

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress-nginx controller..."
kubectl wait --namespace ingress-nginx \
    --for=condition=Available \
    deployment/ingress-nginx-controller \
    --timeout=180s

echo "Waiting for admission webhook jobs..."
kubectl wait --namespace ingress-nginx \
    --for=condition=complete \
    job/ingress-nginx-admission-create \
    --timeout=180s

kubectl wait --namespace ingress-nginx \
    --for=condition=complete \
    job/ingress-nginx-admission-patch \
    --timeout=180s

# 3. Build application image
echo "Building application image..."
docker build -t "$IMAGE_NAME" ./service

# 4. Load image into Kind
echo "Loading image into Kind..."
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

# 5. Deploy application with Helm
echo "Deploying application with Helm..."

helm upgrade --install "$RELEASE_NAME" ./chart \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout 180s

echo "=== Setup completed successfully ==="

kubectl get pods -n "$NAMESPACE"
kubectl get services -n "$NAMESPACE"
kubectl get ingress -n "$NAMESPACE"
