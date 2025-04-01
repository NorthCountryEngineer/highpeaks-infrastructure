# highpeaks-infrastructure

The **High Peaks Infrastructure** repository contains the configuration and infrastructure-as-code for setting up the Kubernetes environment that will host the High Peaks AI platform. 

This repository includes definitions for:
- Creating a local [Kind](https://kind.sigs.k8s.io/) cluster using a custom configuration.
- Bootstrapping Kubernetes namespaces for each microservice (identity, ml, flowise, devops).
- Enhanced security configurations:
  - **RBAC** policies to restrict permissions per namespace.
  - **Sealed Secrets** to safely store sensitive data in Git.
- A GitOps-ready deployment script that builds & loads Docker images from sibling microservice repositories and deploys all components.
- A CI pipeline (via GitHub Actions) to validate YAML files and key deployment scripts.

## Repository Structure

```text
highpeaks-infrastructure/
├── README.md                   # This file – overview, usage, and reproducibility instructions
├── k8s/
│   ├── kind-cluster.yaml       # Kind cluster configuration (includes port mappings)
│   ├── namespaces.yaml         # Definitions for Kubernetes namespaces (e.g., highpeaks-identity, highpeaks-ml, etc.)
│   └── security/
│       ├── rbac/
│       │   ├── highpeaks-ml-rbac.yaml       # Example RBAC for the ML platform
│       │   └── highpeaks-devops-rbac.yaml     # Example RBAC for the DevOps agent
│       └── sealed-secrets/
│           └── mysealedsecret.yaml          # (Example) Sealed Secret manifest (encrypted via kubeseal)
├── run_highpeaks_deployment.sh   # Deployment script to create Kind cluster, load images, and deploy services
└── .github/
    └── workflows/
        └── ci.yml             # CI workflow to validate Kubernetes manifests and deployment scripts
```

## Usage

### Prerequisites

- **Docker** must be installed and running.
- **Kind** must be installed (e.g., via Homebrew: `brew install kind`).
- **kubectl** and **Helm** must be installed.
- The microservice repositories for High Peaks AI (identity, ml, DataSwarm, and devops agent) must be cloned as sibling directories. For example, you might have a directory structure like:

~/dev/highpeaks-ai/
├── highpeaks-infrastructure
├── highpeaks-identity-service
├── highpeaks-ml-platform
├── highpeaks-dataswarm-agenticai-platform   # Flowise service
└── highpeaks-devops-agent

This repository is primarily used to bootstrap and configure the Kubernetes cluster for High Peaks AI:

- **Kind Cluster Setup:** The file `k8s/kind-cluster.yaml` can be used to create a local [Kind](https://kind.sigs.k8s.io/) cluster. It specifies a single-node cluster and includes extra port mappings (e.g., mapping port 8080 on your host to NodePort 30080 in the cluster for access to certain services like Flowise).
- **Namespaces:** Apply `k8s/namespaces.yaml` to create the dedicated namespaces for each microservice (identity, ml, flowise, devops). This ensures each component runs in isolation and aligns with the platform's modular design.
- **CI Validation:** The included GitHub Actions workflow will run `kubectl` in dry-run mode to validate that the YAML files are syntactically correct. This helps catch any configuration errors before applying to a real cluster.

## Development (Local) Workflow

1. **Create Kind Cluster:** Ensure you have Kind installed and Docker running. Create a cluster with:
   ```bash
   kind create cluster --name highpeaks --config k8s/kind-cluster.yaml
   ```
   This will spin up a local Kubernetes cluster named "highpeaks" with the configuration specified (such as port mappings).
2. **Bootstrap Namespaces:** Once the cluster is up, apply the namespaces manifest:
   ```bash
   kubectl apply -f k8s/namespaces.yaml
   ```
   This creates the necessary namespaces (e.g., `highpeaks-identity`, `highpeaks-ml`, etc.) in the cluster.
3. **RBAC:** Apply the RBAC manifests to restrict permissions in each namespace:
```
kubectl apply -f k8s/security/rbac/highpeaks-ml-rbac.yaml
kubectl apply -f k8s/security/rbac/highpeaks-devops-rbac.yaml
```
These manifests (stored in k8s/security/rbac/) define Roles and RoleBindings that grant only necessary permissions to service accounts in their respective namespaces.

**Sealed Secrets:** If you have any sensitive information, create a standard Kubernetes Secret manifest (see Samples/ for a sample secret file) and then encrypt it using the kubeseal CLI. For example:

```kubeseal --controller-namespace kube-system --format yaml < mysecret.yaml > k8s/security/sealed-secrets/mysealedsecret.yaml```

Then, commit and apply the sealed secret:

```kubectl apply -f k8s/security/sealed-secrets/mysealedsecret.yaml```

This ensures that sensitive data is stored securely in Git and only decrypted within the cluster.

3. **Deploy Services:** With the cluster prepared, you can deploy the platform's microservices (from their respective repos) into the cluster. For manual testing, you would follow the deployment instructions in each service's README (or the centralized guide) to apply their manifests into the appropriate namespace.
4. **Build & Load Docker Images and Deploy Services:** Use the provided run_highpeaks_deployment.sh script to automate the following:

    * Build Docker images for the identity service, ML platform, and DevOps agent from their sibling repositories.
    * Pull the official Flowise image.
    * Load all images into the Kind cluster.
    * Deploy the microservices (via Helm, kubectl, or Kustomize) into their respective namespaces.

To run the full deployment, execute:

```
chmod +x run_highpeaks_deployment.sh
./run_highpeaks_deployment.sh
```
5. **Verify and Test:** Check the status of all pods:
```
kubectl get pods --all-namespaces
```

## CI/CD

The infrastructure repo's CI pipeline (`ci.yml`) ensures that configuration changes don't introduce errors:
- On each commit, it will attempt to parse the Kubernetes YAML files (using `kubectl --dry-run`) to catch mistakes.
- In a future enhancement, this pipeline could also validate cluster state (e.g., using `kubeval` or policy checks for Kubernetes best practices).

Since the infrastructure code doesn't produce a container or run an app, there's no build step here. However, consistency and correctness of the configuration are critical to the platform's reliability and security (e.g., making sure the correct namespaces and access controls are in place before deploying services).

## Future Enhancements
   1. GitOps Tool Integration: In the future, integrate Argo CD manifests into this repository so that your cluster can automatically sync changes from multiple microservice repos.

   2. Extended Security: Add more automated security checks (e.g., using OPA Gatekeeper or Conftest) and better secrets management integration.

   3. Environment Overlays: Create additional Kustomize overlays for staging, production, or air-gapped environments.

   4. CI/CD Expansion: Enhance your GitHub Actions workflows to include unit tests, integration tests, and vulnerability scanning.
