variable "project_id" {
  description = "The GCP Project ID"
  type        = string
  default     = "helloworld-334009"
}

variable "region" {
  description = "The GCP Region"
  type        = string
  default     = "us-central1"
}

variable "repo_owner" {
  description = "GitHub Repository Owner"
  type        = string
}

variable "repo_name" {
  description = "GitHub Repository Name"
  type        = string
}
