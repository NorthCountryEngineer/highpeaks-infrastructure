
---

# `highpeaks-infrastructure/README.md`

```markdown
# High Peaks Infrastructure

This repository holds the **infrastructure-as-code** that boots up the Kubernetes environment for the **High Peaks AI** platform, including:

- A local [Kind](https://kind.sigs.k8s.io/) cluster configuration (`kind-cluster.yaml`)
- Namespace definitions (identity, ml, dataswarm, devops)
- Optional RBAC rules to restrict each namespace
- Sample **Sealed Secrets** for managing sensitive data
- A GitOps-oriented script (`run_highpeaks_deployment.sh`) to build and deploy microservices from sibling repos

---

## Repository Structure

```plaintext
highpeaks-infrastructure/
├── README.md
├── k8s/
│   ├── kind-cluster.yaml       # Kind cluster config
│   ├── namespaces.yaml         # Creates highpeaks-identity, highpeaks-ml, etc.
│   └── security/
│       ├── rbac/
│       │   ├── highpeaks-ml-rbac.yaml
│       │   └── highpeaks-devops-rbac.yaml
│       └── sealed-secrets/
│           └── mysealedsecret.yaml
├── run_highpeaks_deployment.sh
└── .github/
    └── workflows/
        └── ci.yml
```

## Prerequisites

   * Docker (running locally)

   * Kind (brew install kind)

   * kubectl and helm

   * The other microservice repos:

      * highpeaks-identity-service (Node.js identity or Keycloak)

      * highpeaks-ml-platform

      * highpeaks-dataswarm-agenticai-platform

      * highpeaks-devops-agent

Your directory might look like:
```plaintext
~/dev/highpeaks-ai/
├── highpeaks-infrastructure
├── highpeaks-identity-service
├── highpeaks-ml-platform
├── highpeaks-dataswarm-agenticai-platform
└── highpeaks-devops-agent
```

2. ## Usage
### Create a Kind Cluster

`kind create cluster --name highpeaks --config k8s/kind-cluster.yaml`

This sets up a local cluster named highpeaks with any custom port mappings.
Apply Namespaces

`kubectl apply -f k8s/namespaces.yaml`

Creates highpeaks-identity, highpeaks-ml, etc.

### Optional: Apply Security (RBAC, Sealed Secrets)

RBAC:
```bash
kubectl apply -f k8s/security/rbac/highpeaks-ml-rbac.yaml
kubectl apply -f k8s/security/rbac/highpeaks-devops-rbac.yaml
```
Sealed Secrets:

`kubectl apply -f k8s/security/sealed-secrets/mysealedsecret.yaml`

(Requires the Sealed Secrets controller to be installed.)

## Deploy Microservices

You can either:

Manually helm install each microservice from its respective repo (e.g. Node.js identity or Keycloak from highpeaks-identity-service, ML platform from highpeaks-ml-platform, etc.),

Or run the script:
```bash
chmod +x run_highpeaks_deployment.sh
./run_highpeaks_deployment.sh
```
Which can:

   * Build Docker images for each microservice

   * Load them into the Kind cluster

   * Deploy them in their respective namespaces

## Verifying the Deployment

Pods:

`kubectl get pods --all-namespaces`

Ensure everything is Running.

Access Services:

Port-forward if needed:
`kubectl port-forward -n highpeaks-identity svc/highpeaks-identity-service 8081:80`
Then http://localhost:8081/health.

Ingress (if you prefer NGINX for local dev).

## CI/CD

The .github/workflows/ci.yml uses kubectl --dry-run to validate YAML.

Future expansions might use kustomize build or helm template checks for more robust verification.

## Future Enhancements

GitOps Tools: Add Argo CD or Flux to auto-sync changes from the identity, ml, devops agent repos.

Security:

   * Use OPA Gatekeeper or Conftest for advanced policy checks.

   * Integrate sealed secrets or Vault for sensitive data.

Multi-Environment Overlays: Kustomize or Helm overlays for staging, production, or air-gapped usage.

CI: Expand the GitHub Actions pipeline to run integration tests or environment checks.

