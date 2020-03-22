variable "ingress_cidr" {}
variable "region" {}

variable "network" {
  description = "Name of the network to deploy instances to."
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable "machine_type" {
  default = "n1-standard-1"
}

data "google_compute_image" "centos" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_address" "bastion" {
  name = "bastion"
}

resource "google_compute_firewall" "bastion_ssh" {
  name    = "bastion-ssh"
  network = "${var.network}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${var.ingress_cidr}"]
  target_tags   = ["bastion"]
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh")}"
}

module "bastion" {
  source            = "GoogleCloudPlatform/managed-instance-group/google"
  version           = ">= 1.1.15"
  region            = "${var.region}"
  machine_type      = "${var.machine_type}"
  name              = "bastion"
  size              = 1
  service_port      = "80"
  service_port_name = "http"
  http_health_check = false
  ssh_fw_rule       = false
  startup_script    = "${data.template_file.user_data.rendered}"
  compute_image     = "${data.google_compute_image.centos.self_link}"
  subnetwork        = "${var.subnetwork}"
  target_tags       = ["bastion"]

  access_config = [
    {
      nat_ip = "${google_compute_address.bastion.address}"
    },
  ]

  metadata {
    enable-oslogin = "true"
  }
}

output "ip" {
  value = "${google_compute_address.bastion.address}"
}
