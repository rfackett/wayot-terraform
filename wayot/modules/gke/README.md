# Google Kubernetes Engine (GKE)

Requires both the `google` and `google-beta` providers, as beta is use if deploying a regional cluster (`var.regional`).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cost\_center | Cost Center for billing purposes | string | `caleb@foghornconsulting.com` | no |
| enable\_dashboard | Whether to enabled the Dashboard addon | string | `true` | no |
| environment | - | string | `dev` | no |
| ingress\_cidr | CIDR range for master ingress | string | `127.0.0.1/32` | no |
| machine\_type | VM instance type | string | `n1-standard-1` | no |
| name | - | string | `fogops` | no |
| network | GCP network for deployment | string | `default` | no |
| node\_count | The number of nodes to create in this cluster (not including the Kubernetes master). | string | `1` | no |
| oauth\_scopes | Oauth scopes for nodes | list | `<list>` | no |
| pool\_spec | Node pools by machine type | map | `<map>` | no |
| preemptible | Whether the nodes are preemptible instances | string | `true` | no |
| region | - | string | `us-central1` | no |
| regional | Whether to define a regional GKE cluster versus a zonal one | string | `true` | no |
| service\_account | The service account to be used by the Node VMs. In order to use the configured oauth_scopes for logging and monitoring, the service account being used needs the roles/logging.logWriter and roles/monitoring.metricWriter roles. | string | `` | no |
| subnetworks | Subnetworks for deployment | list | - | yes |
| tags | list of instance tags applied to all nodes. Tags are used to identify valid sources or targets for network firewalls | list | `<list>` | no |
| version | The current version of the application | string | `0.01` | no |

## Outputs

| Name | Description |
|------|-------------|
| admin\_password | - |
| client\_certificate | Base64 encoded public certificate used by clients to authenticate to the cluster endpoint |
| client\_key | Base64 encoded private key used by clients to authenticate to the cluster endpoint |
| cluster\_ca\_certificate | Base64 encoded public certificate that is the root of trust for the cluster |
| cluster\_name | The name of the GKE cluster (useful for get-credentials) |
| master\_ip | The IP address of this cluster's Kubernetes master |
| version | The current master version |
