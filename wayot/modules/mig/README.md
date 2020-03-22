# Managed Instance Group

## Updates

When updating a MIG, you can observe the status of the update by querying the API:

    gcloud beta compute instance-groups managed describe $GROUP_NAME --zone=$ZONE --format='json(currentActions)'

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cidr\_ingress | CIDR ranges for SSH ingress to MIG | list | `<list>` | no |
| group\_size | Number of instances in the MIG | string | `1` | no |
| metadata | Map of metadata values to pass to instances. | map | `<map>` | no |
| name | Name for the deployment | string | `mig` | no |
| network | GCP network for deployment | string | - | yes |
| owner | Resource owner (e.g. your email address) | string | `caleb@foghornconsulting.com` | no |
| region | GCP region | string | `us-central1` | no |
| service\_port | Ingress service port | string | `80` | no |
| subnetworks | Subnetworks for deployment | list | - | yes |
| tags | Tag added to instances for firewall and networking. | list | `<list>` | no |
| user\_data | User data (startup-script in GCP parlance) for the instances | string | `` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance\_group | - |

