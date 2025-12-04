output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "dev_cluster_name" {
  value = google_container_cluster.dev.name
}

output "dev_cluster_endpoint" {
  value = google_container_cluster.dev.endpoint
}

output "artifact_registry_repo" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.name}"
}

output "cloud_deploy_pipeline" {
  value = google_clouddeploy_delivery_pipeline.pipeline.name
}
