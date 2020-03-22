output "name" {
  value = "${google_compute_network.gcp-vpc.name}"
}

output "subnetworks" {
  value = "${google_compute_subnetwork.set.*.name}"
}
