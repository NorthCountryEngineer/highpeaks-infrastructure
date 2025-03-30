# highpeaks-infrastructure

The **High Peaks Infrastructure** repository contains the configuration and infrastructure-as-code for setting up the Kubernetes environment that will host the High Peaks AI platform. It includes definitions for the base Kubernetes cluster (for local development), essential namespaces for each microservice, and a CI pipeline to ensure the configs remain valid.

## Repository Structure

```text
highpeaks-infrastructure/
├── README.md           # Overview and usage of the infrastructure configurations
├── k8s/
│   ├── kind-cluster.yaml  # Configuration for creating a local Kind cluster for High Peaks
│   └── namespaces.yaml    # Defines Kubernetes namespaces for platform microservices
└── .github/
    └── workflows/
        └── ci.yml      # CI workflow to validate Kubernetes manifests (syntax check)
```

## Usage

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
3. **Deploy Services:** With the cluster prepared, you can deploy the platform's microservices (from their respective repos) into the cluster. For manual testing, you would follow the deployment instructions in each service's README (or the centralized guide) to apply their manifests into the appropriate namespace.
4. **GitOps (Future):** In a production scenario, this repository could be used to host GitOps tooling (like Argo CD or Flux) definitions. For example, you might have Argo CD install manifests here to automatically sync the applications from the other repos. At this stage, we have not included those tools, but the structure could be extended to support them.

## CI/CD

The infrastructure repo's CI pipeline (`ci.yml`) ensures that configuration changes don't introduce errors:
- On each commit, it will attempt to parse the Kubernetes YAML files (using `kubectl --dry-run`) to catch mistakes.
- In a future enhancement, this pipeline could also validate cluster state (e.g., using `kubeval` or policy checks for Kubernetes best practices).

Since the infrastructure code doesn't produce a container or run an app, there's no build step here. However, consistency and correctness of the configuration are critical to the platform's reliability and security (e.g., making sure the correct namespaces and access controls are in place before deploying services).
