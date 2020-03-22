# terraform {
#   backend "gcs" {
#     bucket  = "wayot-terraform"
#     prefix  = "states/gke"
#   }
# }

variable "region" {
  default = "us-central1"
}

variable "project" {
  default = "ivory-cycle-233717"
}

variable "pool_spec" {
  default = {
    "n1-standard-2" = 1
  }
}

data "google_compute_zones" "available" {
  provider = "google"
}

data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "${data.google_compute_network.default.name}"
  region = "${var.region}"
}

data "google_container_engine_versions" "default" {
  zone = "${data.google_compute_zones.available.names[1]}"
}

provider "google" {
  credentials = "/Users/ryan/.config/gcloud/wayot-700ed773e066.json"
  project = "${var.project}"
  region  = "${var.region}"
}

provider "google-beta" {
  credentials = "/Users/ryan/.config/gcloud/wayot-700ed773e066.json"
  # Necessary if defining a Regional Cluster (where `region` is set in the google_container_cluster resource definition)
  # https://cloud.google.com/kubernetes-engine/docs/concepts/regional-clusters
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#region
  project = "${var.project}"
  region = "${var.region}"
}

data "external" "ip" {
  program = ["bash", "-c",
    "jq -n --arg this `curl checkip.amazonaws.com` '{ip:$this}'",
  ]
}

module "wayot_k8s" {
  source       = "../modules/gke"
  region       = "${var.region}"
  name         = "search"
  environment  = "wayot"
  cost_center  = "ryan.fackett@gmail.com"
  gke_version  = "${data.google_container_engine_versions.default.latest_node_version}"
  regional     = true
  remove_default_node_pool = true
  machine_type = "n1-standard-2"
  pool_spec    = "${var.pool_spec}"
  additional_zones = ["${data.google_compute_zones.available.names[1]}"]
  network      = "${data.google_compute_network.default.name}"
  subnetworks  = ["${element(data.google_compute_subnetwork.default.*.name, 0)}"]
  ingress_cidr = "${data.external.ip.result.ip}/32"

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

output "kubernetes_master_ip" {
  value = "${module.wayot_k8s.master_ip[0]}"
}
