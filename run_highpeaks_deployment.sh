#!/bin/bash
set -euo pipefail

# High Peaks AI Deployment Script
# This script sets up a Kind cluster, loads Docker images for High Peaks AI services,
# and deploys the platform into the cluster.

# --- Configuration Variables ---
CLUSTER_NAME="highpeaks"
KIND_CONFIG="./k8s/kind-cluster.yaml"
NAMESPACE_MANIFEST="./k8s/namespaces.yaml"

# Paths to sibling repositories (adjust these paths if your directory structure is different)
IDENTITY_REPO="../highpeaks-identity-service"
ML_REPO="../highpeaks-ml-platform"
FLOWISE_REPO="../highpeaks-dataswarm-agenticai-platform"
DEVOPS_AGENT_REPO="../highpeaks-devops-agent"

# Docker image names (ensure these match your service configurations)
IDENTITY_IMAGE="highpeaks-identity-service:latest"
ML_IMAGE="highpeaks-ml-platform:latest"
DEVOPS_AGENT_IMAGE="highpeaks-devops-agent:latest"
FLOWISE_IMAGE="flowiseai/flowise:latest"

# --- Functions ---
check_prerequisites() {
    echo "Checking required tools..."
    command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is not installed. Aborting."; exit 1; }
    command -v kind >/dev/null 2>&1 || { echo >&2 "Kind is not installed. Aborting."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is not installed. Aborting."; exit 1; }
    command -v helm >/dev/null 2>&1 || { echo >&2 "Helm is not installed. Aborting."; exit 1; }
}

create_kind_cluster() {
    echo "Creating Kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
}

apply_namespaces() {
    echo "Applying namespaces..."
    kubectl apply -f "$NAMESPACE_MANIFEST"
}

build_and_load_image() {
    local repo_path=$1
    local image_name=$2
    echo "Building Docker image for $repo_path as $image_name..."
    (cd "$repo_path" && docker build -t "$image_name" .)
    echo "Loading image $image_name into Kind cluster..."
    kind load docker-image "$image_name" --name "$CLUSTER_NAME"
}

pull_and_load_flowise() {
    echo "Pulling DataSwarm image..."
    docker pull "$FLOWISE_IMAGE"
    echo "Loading Flowise image into Kind cluster..."
    kind load docker-image "$FLOWISE_IMAGE" --name "$CLUSTER_NAME"
}

deploy_identity_service() {
    echo "Deploying Identity Service via Helm..."
    helm install highpeaks-identity "$IDENTITY_REPO/charts/highpeaks-identity" -n highpeaks-identity --create-namespace
}

deploy_ml_platform() {
    echo "Deploying ML Platform service..."
    kubectl apply -f "$ML_REPO/infrastructure/k8s/namespace.yaml"
    kubectl apply -f "$ML_REPO/infrastructure/k8s/storage.yaml"
    kubectl apply -f "$ML_REPO/infrastructure/k8s/mlflow.yaml"
    kubectl apply -f "$ML_REPO/infrastructure/k8s/deployment.yaml"
    kubectl apply -f "$ML_REPO/infrastructure/k8s/service.yaml"
    echo "ML Platform Kubernetes resources deployed."
}


deploy_flowise_service() {
    echo "Deploying Flowise service..."
    kubectl apply -n highpeaks-flowise -f "$FLOWISE_REPO/k8s/deployment.yaml"
    kubectl apply -n highpeaks-flowise -f "$FLOWISE_REPO/k8s/service.yaml"
}

deploy_devops_agent() {
    echo "Deploying DevOps Agent using Kustomize (dev overlay)..."
    kubectl apply -n highpeaks-devops -k "$DEVOPS_AGENT_REPO/k8s/overlays/dev"
}

# --- Main Script Execution ---
echo "Starting High Peaks AI platform deployment..."

check_prerequisites

echo "Step 1: Creating Kind cluster..."
create_kind_cluster

echo "Step 2: Applying namespaces..."
apply_namespaces

echo "Step 3: Building and loading Docker images..."
build_and_load_image "$IDENTITY_REPO" "$IDENTITY_IMAGE"
build_and_load_image "$ML_REPO" "$ML_IMAGE"
build_and_load_image "$DEVOPS_AGENT_REPO" "$DEVOPS_AGENT_IMAGE"

echo "Step 4: Pulling and loading Flowise image..."
pull_and_load_flowise

echo "Step 5: Deploying services..."
deploy_identity_service
deploy_ml_platform
deploy_flowise_service
deploy_devops_agent

echo "High Peaks AI platform deployment is complete!"

# Optional instructions:
echo "To verify deployment, run:"
echo "  kubectl get pods --all-namespaces"
echo ""
echo "Access instructions:"
echo " - Identity Service: Port-forward using 'kubectl port-forward -n highpeaks-identity svc/highpeaks-identity-service 8081:80' and visit http://localhost:8081/health"
echo " - ML Platform: Port-forward using 'kubectl port-forward -n highpeaks-ml svc/highpeaks-ml-platform 5000:80' and visit http://localhost:5000/predict"
echo " - Flowise Service: Access via NodePort on port 30080 (or port-forward 'kubectl port-forward -n highpeaks-flowise svc/highpeaks-flowise-service 8080:3000' and visit http://localhost:8080)"
echo " - DevOps Agent: Port-forward using 'kubectl port-forward -n highpeaks-devops svc/highpeaks-devops-agent 8000:80' and visit http://localhost:8000/health"
