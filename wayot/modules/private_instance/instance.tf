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

variable "boot_image" {
  default = "debian-cloud/debian-9"
}

resource "random_pet" "name" {
  length = 1
}

data "google_compute_zones" "available" {}

module "nat" {
  source            = "GoogleCloudPlatform/nat-gateway/google"
  version           = ">= 1.2.2"
  region            = "${var.region}"
  network           = "${var.network}"
  subnetwork        = "${var.subnetwork}"
  ssh_source_ranges = ["127.0.0.1/32"]
}

resource "google_compute_instance" "private" {
  name         = "${random_pet.name.id}"
  machine_type = "${var.machine_type}"
  zone         = "${element(data.google_compute_zones.available.names, 0)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnetwork}"
  }

  tags = ["nat-${var.region}", "private"]

  metadata {
    enable-oslogin = "true"
  }
}

output "ip" {
  value = "${google_compute_instance.private.network_interface.0.address}"
}
