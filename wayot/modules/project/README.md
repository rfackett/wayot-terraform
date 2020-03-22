# GCP Project module

**Nota Bene**: This module will not work locally (with an individual's
GCP account), as it requires billing permissions,. Use an admin
service account:

    export TF_VAR_credential_file=./fogsource-terraform-admin.json

This module is equivalent to the following `gcloud` commands:

    export NAME=new-project-xyz
    export BILLING_ACCT_ID=abcdef-123456-123456
    gcloud projects create --organization=42918743314 $?NAME
    gcloud beta billing projects link $NAME --billing-account=$BILLING_ACCT_ID
    gcloud services enable $A_FEW_SERVICES

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account\_id | Billing account to use (default is Foghorn's) | string | `009C14-7421BC-074496` | no |
| cost\_center | Cost center for tagging resources | string | - | yes |
| environment | Environment (dev/stg/prod, etc.) | string | `dev` | no |
| name | Name to give the project | string | - | yes |
| org\_id | Organization ID (default is Foghorn's) | string | `42918743314` | no |
| owners | User emails to make project owners | list | `<list>` | no |
| region | GCP region | string | `us-west2` | no |
| services | - | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | GCP project ID |

