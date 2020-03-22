provider "google" {}
provider "google-beta" {}

variable "node_count" {
  description = "The number of nodes to create in this cluster (not including the Kubernetes master)."
  default     = 1
}

variable "region" {
  default = "us-central1"
}

variable "name" {
  default = "wayot"
}

variable "environment" {
  default = "search"
}

variable "enable_dashboard" {
  description = "Whether to enabled the Dashboard addon"
  default     = true
}

variable "remove_default_node_pool" {
  description = "Whether to remove the default node pool"
  default     = false
}

variable "tags" {
  description = "list of instance tags applied to all nodes. Tags are used to identify valid sources or targets for network firewalls"
  default     = []
  type        = "list"
}

variable "machine_type" {
  description = "VM instance type"
  default     = "n1-standard-1"
}

variable "service_account" {
  description = "The service account to be used by the Node VMs. In order to use the configured oauth_scopes for logging and monitoring, the service account being used needs the roles/logging.logWriter and roles/monitoring.metricWriter roles."
  default     = ""
}

variable "version" {
  description = "The current version of the application"
  default     = "0.01"
}

variable "cost_center" {
  description = "Cost Center for billing purposes"
  default     = "ryan.fackett@gmail.com"
}

variable "regional" {
  description = "Whether to define a regional GKE cluster versus a zonal one"
  default     = true
}

variable "network" {
  description = "GCP network for deployment"
  default     = "default"
  type        = "string"
}

variable "subnetworks" {
  description = "Subnetworks for deployment"
  type        = "list"
}

variable "ingress_cidr" {
  description = "CIDR range for master ingress"
  default     = "127.0.0.1/32"
}

variable "preemptible" {
  description = "Whether the nodes are preemptible instances"
  default     = true
}

variable "additional_zones" {
  description = "Additional zones for worker nodes"
  default     = []
  type        = "list"
}

variable "pool_spec" {
  description = "Node pool counts by machine type"
  default     = {}
  type        = "map"

  # Non-null specification looks like:
  # pool_spec = {
  #   "n1-standard-1" = 1
  # }
}

variable "oauth_scopes" {
  description = "Oauth scopes for nodes"

  default = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
  ]

  type = "list"
}

variable "gke_version" {
  description = "Master and Node version, defaults to GKE default"
  default     = ""
  type        = "string"
}

locals {
  name = "${var.name}-${var.environment}"

  labels = {
    terraform = true
    env       = "${var.environment}"
    app       = "${var.name}"
  }

  kubernetes_labels = {
    "app.kubernetes.io/name"       = "${local.name}"
    "app.kubernetes.io/instance"   = "${random_id.main.hex}"
    "app.kubernetes.io/version"    = "${var.version}"
    "app.kubernetes.io/managed-by" = "Terraform"
    "cost_center"                  = "${replace(replace(var.cost_center, "@", ".at."), ".", "_")}"
  }
}

data "google_compute_zones" "available" {
  provider = "google"
}

resource "google_container_node_pool" "poolset" {
  count      = "${length(keys(var.pool_spec))}"
  name       = "${local.name}"
  region     = "${var.region}"
  cluster    = "${element(coalescelist(google_container_cluster.regional.*.name, google_container_cluster.zonal.*.name), 0)}"
  node_count = "${element(values(var.pool_spec), count.index)}"
  version    = "${var.gke_version}"

  node_config {
    preemptible  = "${var.preemptible}"
    machine_type = "${element(keys(var.pool_spec), count.index)}"
    metadata     = "${merge(local.labels, map("machine_type", element(values(var.pool_spec), count.index)))}"
    oauth_scopes = "${var.oauth_scopes}"
  }
}

resource "google_container_cluster" "regional" {
  count            = "${var.regional ? 1 : 0 }"
  provider         = "google-beta"
  additional_zones = ["${var.additional_zones}"]
  name               = "${local.name}-${random_id.main.hex}"
  min_master_version = "${var.gke_version}"
  initial_node_count = "${var.node_count}"
  node_version       = "${var.gke_version}"
  resource_labels    = "${local.labels}"
  remove_default_node_pool = "${var.remove_default_node_pool}"
  network    = "${var.network}"
  subnetwork = "${element(var.subnetworks, 0)}"

  # This property is in beta, and should be used with the terraform-provider-google-beta provider
  region = "${var.region}"

  private_cluster_config {
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
    enable_private_nodes    = true
  }

  ip_allocation_policy {}

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${var.ingress_cidr}"
      display_name = "admin ingress IP"
    }
  }

  addons_config {
    kubernetes_dashboard {
      disabled = "${var.enable_dashboard ? false : true}"
    }
  }

  master_auth {
    username = ""
    password = ""

    # basic authentication is disabled when user/pass are empty
    # username = "admin"
    # password = "${random_id.password.hex}"
  }

  node_config {
    oauth_scopes = "${var.oauth_scopes}"
    labels       = "${local.kubernetes_labels}"
    tags         = "${var.tags}"
  }

  timeouts {
    update = "15m"
  }
}

resource "random_id" "main" {
  byte_length = 4
}

resource "random_id" "password" {
  byte_length = 8
}

resource "google_container_cluster" "zonal" {
  count              = "${var.regional ? 0 : 1 }"
  provider           = "google"
  name               = "${local.name}-${random_id.main.hex}"
  initial_node_count = "${var.node_count}"
  resource_labels    = "${local.labels}"

  #service_account   = "${var.service_account}"
  network    = "${var.network}"
  subnetwork = "${element(var.subnetworks, 0)}"

  # The attributes `region` and `zone` are mutually exclusive
  zone = "${element(data.google_compute_zones.available.names, 0)}"

  additional_zones = ["${var.additional_zones}"]

  private_cluster_config {
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
    enable_private_nodes    = true
  }

  ip_allocation_policy {}

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${var.ingress_cidr}"
      display_name = "admin ingress IP"
    }
  }

  addons_config {
    kubernetes_dashboard {
      disabled = "${var.enable_dashboard ? false : true}"
    }
  }

  master_auth {
    username = ""
    password = ""

    # basic authentication is disabled when user/pass are empty
    # username = "admin"
    # password = "${random_id.password.hex}"
  }

  node_config {
    metadata     = "${local.labels}"
    labels       = "${local.kubernetes_labels}"
    tags         = "${var.tags}"
    oauth_scopes = "${var.oauth_scopes}"
  }

  timeouts {
    update = "15m"
  }
}

output "cluster_name" {
  description = "The name of the GKE cluster (useful for get-credentials)"
  value       = "${coalescelist(google_container_cluster.regional.*.name, google_container_cluster.zonal.*.name)}"
}

output "master_ip" {
  description = "The IP address of this cluster's Kubernetes master"
  value       = "${coalescelist(google_container_cluster.regional.*.endpoint, google_container_cluster.zonal.*.endpoint)}"
}

output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the cluster endpoint"
  value       = "${coalescelist(google_container_cluster.regional.*.master_auth.0.client_certificate, google_container_cluster.zonal.*.master_auth.0.client_certificate)}"
}

output "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the cluster endpoint"
  value       = "${coalescelist(google_container_cluster.regional.*.master_auth.0.client_key, google_container_cluster.zonal.*.master_auth.0.client_key)}"
}

output "cluster_ca_certificate" {
  description = " Base64 encoded public certificate that is the root of trust for the cluster"
  value       = "${coalescelist(google_container_cluster.regional.*.master_auth.0.cluster_ca_certificate, google_container_cluster.zonal.*.master_auth.0.cluster_ca_certificate)}"
}

output "version" {
  description = "The current master version"
  value       = "${coalescelist(google_container_cluster.regional.*.master_version, google_container_cluster.zonal.*.master_version)}"
}

output "admin_password" {
  value = "${random_id.password.hex}"
}
