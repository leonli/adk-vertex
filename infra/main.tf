terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable necessary APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "clouddeploy.googleapis.com",
    "compute.googleapis.com",
    "sourcerepo.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = "agent-repo"
  description   = "Docker repository for Agent App"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# GKE Autopilot Cluster
resource "google_container_cluster" "primary" {
  name     = "agent-cluster"
  location = var.region
  
  enable_autopilot = true

  # Set deletion_protection to false for demo purposes to allow easy cleanup
  deletion_protection = false

  depends_on = [google_project_service.apis]
}

# Cloud Deploy Pipeline
resource "google_clouddeploy_delivery_pipeline" "pipeline" {
  location = var.region
  name     = "agent-pipeline"

  serial_pipeline {
    stages {
      profiles = ["prod"]
      target_id = google_clouddeploy_target.prod.name
    }
  }
  
  depends_on = [google_project_service.apis]
}

# Cloud Deploy Target
resource "google_clouddeploy_target" "prod" {
  location = var.region
  name     = "prod-target"

  gke {
    cluster = google_container_cluster.primary.id
  }

  require_approval = false
  
  depends_on = [google_project_service.apis]
}

# Service Account for Cloud Build
resource "google_service_account" "cloudbuild_sa" {
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
}

# Grant Cloud Build SA permissions
resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/clouddeploy.releaser",
    "roles/container.developer",
    "roles/storage.objectViewer"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

# Cloud Build Trigger
# Note: This assumes the repo is already connected to Cloud Build via the GitHub App.
resource "google_cloudbuild_trigger" "push_trigger" {
  name     = "agent-push-trigger"
  location = var.region

  github {
    owner = var.repo_owner
    name  = var.repo_name
    push {
      branch = "^main$"
    }
  }

  service_account = google_service_account.cloudbuild_sa.id
  filename        = "cloudbuild.yaml"

  depends_on = [google_project_service.apis]
}
