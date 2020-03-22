resource "google_compute_firewall" "allow_ssh_internal" {
  count   = "${length(local.subnetworks)}"
  name    = "ssh-internal"
  network = "${google_compute_network.gcp-vpc.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${cidrsubnet(var.vpc_cidr, var.newbits,  count.index + var.netnum_shift) }"]
}

resource "google_compute_firewall" "allow-all-internal" {
  count   = "${length(local.subnetworks)}"
  name    = "allow-all-internal"
  network = "${google_compute_network.gcp-vpc.name}"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["${cidrsubnet(var.vpc_cidr, var.newbits,  count.index + var.netnum_shift) }"]
}
