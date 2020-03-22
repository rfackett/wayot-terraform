# GCP Network

A `m-gcp-vpc`, if you will.

## Usage

```
module "vpc" {
  source = "../../modules/network"
  name = "${local.name}"
  vpc_cidr = "10.40.0.0/16"
  newbits = 8
  subnetworks = ["${var.region}"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | - | string | `fogops` | no |
| netnum\_shift | The shift in subnet creation between subnets | string | `0` | no |
| newbits | This controls subnet size, default is 5, which against a /16 give a subnet size of /21 with 2045 addresses. | string | `8` | no |
| region | - | string | `us-central1` | no |
| subnetworks | List of regions to deploy subnetworks into | list | `<list>` | no |
| vpc\_cidr | - | string | `10.100.0.0/12` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | - |
| subnetworks | - |

