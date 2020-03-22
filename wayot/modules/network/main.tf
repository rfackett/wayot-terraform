provider "google" {}

variable "region" {
  default = "us-central1"
}

variable "name" {
  default = "fogops"
}

variable "vpc_cidr" {
  default = "10.128.0.0/12"
}

data "google_compute_regions" "available" {}

variable "subnetworks" {
  # TODO: this wording is poor. Are they regions or subnetworks?
  # Should we iterate over `data.google_compute_zones.available` instead?
  description = "List of regions to deploy subnetworks into"

  default = []
}

variable "netnum_shift" {
  default     = 0
  description = "The shift in subnet creation between subnets"
}

variable "newbits" {
  description = "This controls subnet size, default is 5, which against a /16 give a subnet size of /21 with 2045 addresses."
  default     = 8
}

locals {
  subnetworks = "${coalescelist(var.subnetworks, data.google_compute_regions.available.names)}"
}

resource "google_compute_network" "gcp-vpc" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = "false"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_subnetwork" "set" {
  count         = "${length(local.subnetworks)}"
  name          = "${var.name}-${element(local.subnetworks, count.index)}"
  network       = "${google_compute_network.gcp-vpc.id}"
  ip_cidr_range = "${cidrsubnet(var.vpc_cidr, var.newbits,  count.index + var.netnum_shift) }"
  region        = "${element(local.subnetworks, count.index)}"
}
