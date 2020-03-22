variable "region" {
  description = "GCP region"
  default     = "us-west2"
}

variable "cost_center" {
  description = "Cost center for tagging resources"
}

variable "name" {
  description = "Name to give the project"
}

variable "environment" {
  default     = "dev"
  description = "Environment (dev/stg/prod, etc.)"
}

variable "owners" {
  description = "User emails to make project owners"
  default     = []
}

locals {
  labels = {
    terraform = "true"

    #cost_center  = "${replace(lower(var.cost_center), "@", ".at.")}"
    environment = "${lower(var.environment)}"
    application = "${lower(var.name)}"
    name        = "${lower(var.environment)}-${replace(lower(var.name), " ", "")}"
  }
}

variable "services" {
  default = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "oslogin.googleapis.com",
  ]
}

variable "billing_account_id" {
  description = "Billing account to use (default is Foghorn's)"
  default     = "009C14-7421BC-074496"
}

variable "org_id" {
  description = "Organization ID (default is Foghorn's)"
  default     = "42918743314"
}

resource "random_id" "id" {
  byte_length = 4
}

resource "google_project" "main" {
  name            = "${local.labels["name"]}"
  project_id      = "${var.name}-${random_id.id.hex}"
  org_id          = "${var.org_id}"
  billing_account = "${var.billing_account_id}"
  labels          = "${local.labels}"
}

resource "google_project_services" "project" {
  project  = "${google_project.main.id}"
  services = "${var.services}"
}

resource "google_project_iam_member" "project" {
  count   = "${length(var.owners)}"
  project = "${google_project_services.project.project}"
  role    = "roles/owner"
  member  = "user:${element(var.owners, count.index)}"
}

output "id" {
  description = "GCP project ID"
  value       = "${google_project_services.project.project}"
}
