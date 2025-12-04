# GKE AI Agent Demo with Vertex AI

This project demonstrates a production-ready deployment of an AI Agent application on **Google Kubernetes Engine (GKE) Autopilot**. It features a complete GitOps-style CI/CD pipeline using **Cloud Build** and **Cloud Deploy**, with advanced networking capabilities via **Gateway API**.

## 🏗️ Architecture

The system consists of two environments (**Dev** and **Prod**) and uses a Global External Load Balancer to route traffic.

```mermaid
graph TD
    User((User)) -->|HTTPS| GCLB[Global External LB<br>(Gateway API)]
    
    subgraph cluster_gke [GKE Autopilot Cluster]
        direction TB
        GCLB -->|HTTPRoute| Service[K8s Service<br>(ClusterIP)]
        
        subgraph cluster_affinity [Session Affinity Cookie]
            Service --> Pod1[Agent Pod 1]
            Service --> Pod2[Agent Pod 2]
            Service --> Pod3[Agent Pod 3]
        end
    end

    Pod1 -.->|Workload Identity| VertexAI[Vertex AI<br>(Gemini Model)]
    
    subgraph cluster_cicd [CI/CD Pipeline]
        direction TB
        Git[GitHub Repo] -->|Push| CB[Cloud Build]
        CB -->|Build & Push| AR[Artifact Registry]
        CB -->|Create Release| CD[Cloud Deploy]
        CD -->|Auto Deploy| Dev[Dev Environment]
        CD -->|Promote & Canary| Prod[Prod Environment]
    end
```

## ✨ Key Features

-   **GKE Autopilot**: Fully managed Kubernetes clusters for Dev and Prod.
-   **Gateway API**: Uses `gke-l7-global-external-managed` for a modern, global Load Balancer.
-   **Canary Deployment**: Production releases use a **50% Canary** strategy via Cloud Deploy.
-   **Session Affinity**: Configured via `GCPBackendPolicy` to ensure sticky sessions for the in-memory agent state.
-   **Workload Identity**: Secure, keyless authentication to Vertex AI.
-   **Health Checks**: Custom `HealthCheckPolicy` ensuring the LB checks `/healthz` instead of the default root path.

## 🚀 Getting Started

### Prerequisites
-   Google Cloud Project (with Billing enabled).
-   `terraform` installed.
-   `gcloud` CLI installed.
-   GitHub Repository connected to Cloud Build.

### 1. Infrastructure Setup
Provision the GKE clusters, CI/CD pipeline, and IAM roles using Terraform.

```bash
cd infra
# Initialize Terraform
terraform init

# Apply Configuration
# Replace with your GitHub details
terraform apply -var="repo_owner=YOUR_GITHUB_USER" -var="repo_name=YOUR_REPO_NAME"
```

### 2. Application Deployment
The deployment is automated via Git triggers.

1.  Commit and push your changes to the `main` branch.
    ```bash
    git add .
    git commit -m "feat: Initial deployment"
    git push
    ```
2.  **Cloud Build** will automatically build the image and create a Cloud Deploy release.
3.  **Cloud Deploy** will:
    -   Automatically deploy to the **Dev** cluster.
    -   Wait for manual approval to promote to **Prod**.
4.  Approve the release in the Google Cloud Console to start the **50% Canary** rollout to Prod.

## ⚠️ Important Notes & Troubleshooting

### Health Checks (`/healthz`)
The application exposes a dedicated health check endpoint at `/healthz`.
-   **Why**: The root path `/` may return `307 Redirects` (e.g., to a UI), which causes the Load Balancer to mark the backend as unhealthy.
-   **Config**: We use a `HealthCheckPolicy` (`env/healthcheckpolicy.yaml`) to explicitly tell the Gateway to check `/healthz`.

### Session Affinity (Sticky Sessions)
The AI Agent stores conversation history in-memory.
-   **Issue**: Without affinity, requests might hit different pods, causing "Session Not Found" (404) errors.
-   **Solution**: A `GCPBackendPolicy` (`env/backendpolicy.yaml`) is applied to the Service to enable `GENERATED_COOKIE` affinity. This ensures a user stays connected to the same pod.

### Gateway Provisioning
When deploying the `Gateway` resource for the first time, it may take **5-10 minutes** for the Global Load Balancer IP to be provisioned and for traffic to start flowing.
