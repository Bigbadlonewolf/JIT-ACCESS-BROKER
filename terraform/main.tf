terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.7"
}

# Variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
  default     = "Bigbadlonewolf"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "JIT-ACCESS-BROKER"
}

# Enable required GCP APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# Service account for JIT access provisioning
resource "google_service_account" "jit_provisioner" {
  account_id   = "jit-access-provisioner"
  display_name = "JIT Access Provisioner"
  description  = "Service account for JIT access provisioning via GitHub Actions"
}

# Grant the provisioner SA ability to manage IAM policies
resource "google_project_iam_member" "jit_security_admin" {
  project = var.project_id
  role    = "roles/iam.securityAdmin"
  member  = "serviceAccount:${google_service_account.jit_provisioner.email}"
}

# Workload Identity Federation for GitHub Actions
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-jit-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity pool for JIT Access Broker GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = "assertion.repository == '${var.github_owner}/${var.github_repo}'"
}

# Allow GitHub Actions to impersonate the provisioner SA
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.jit_provisioner.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
}

# Outputs
output "provisioner_sa" {
  value = google_service_account.jit_provisioner.email
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}
