data "template_file" "startup" {
  template = "${file("${path.module}/startup-script.sh")}"

  vars = {
    port = "${var.service_port}"
  }
}

variable "user_data" {
  description = "User data (startup-script in GCP parlance) for the instances"
  default     = ""
}

data "google_compute_zones" "available" {}

variable "region" {
  description = "GCP region"
  default     = "us-central1"
}

variable "name" {
  description = "Name for the deployment"
  type        = "string"
  default     = "mig"
}

variable "network" {
  description = "GCP network for deployment"
  type        = "string"
}

variable "subnetworks" {
  description = "Subnetworks for deployment"
  type        = "list"
}

variable "tags" {
  description = "Tag added to instances for firewall and networking."
  default     = []
  type        = "list"
}

variable "cidr_ingress" {
  description = "CIDR ranges for SSH ingress to MIG"
  default     = ["0.0.0.0/0"]
  type        = "list"
}

variable "service_port" {
  description = "Ingress service port"
  default     = 80
}

variable "group_size" {
  description = "Number of instances in the MIG"
  default     = 1
}

variable "metadata" {
  description = "Map of metadata values to pass to instances."
  default     = {}
  type        = "map"
}

variable "owner" {
  description = "Resource owner (e.g. your email address)"
  default     = "caleb@foghornconsulting.com"
}

locals {
  startup_script = "${var.user_data == "" ? data.template_file.startup.rendered : var.user_data}"

  _metadata = {
    CostCenter = "${var.owner}"
  }

  metadata = "${merge(local._metadata, var.metadata)}"
}

module "mig" {
  source            = "GoogleCloudPlatform/managed-instance-group/google"
  version           = ">= 1.1.15"
  region            = "${var.region}"
  zone              = "${element(data.google_compute_zones.available.names, 0)}"
  name              = "${var.name}"
  network           = "${var.network}"
  subnetwork        = "${element(var.subnetworks, 0)}"
  size              = "${var.group_size}"
  service_port      = "${var.service_port}"
  service_port_name = "http"

  #  target_pools      = ["${module.gce-lb-fr.target_pool}"]
  target_tags       = ["${var.tags}"]
  startup_script    = "${local.startup_script}"
  ssh_source_ranges = ["${var.cidr_ingress}"]
  access_config     = []
  metadata          = "${local.metadata}"
}

output "instance_group" {
  value = "${module.mig.instance_group}"
}

output "instances" {
  value = "${module.mig.instances}"
}
