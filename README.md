# OCI FinOps Monitor — Terraform (global/portable format)

This module deploys the OCI FinOps Monitor dashboard end-to-end on any OCI
tenancy: it creates (or reuses) networking, launches a compute instance,
bakes the app onto the VM via cloud-init, starts it as a systemd service,
and grants the IAM policy needed to read cost/usage data — all driven by
variables, with no hardcoded OCIDs, regions, or images. Anyone with an OCI
account and Terraform can clone this and run it against their own tenancy.

## What gets created

- (Optional, default on) A new VCN, public subnet, internet gateway, route
  table, and security list opening SSH (22) and the dashboard port (8501)
- A compute instance (default: `VM.Standard.E4.Flex`, 2 OCPU / 16GB, latest
  Ubuntu 22.04 image — auto-discovered, not hardcoded)
- Cloud-init that installs Python, sets up a venv, installs the app, and
  runs it as a `systemd` service on boot
- An IAM policy granting an existing group read access to the Usage API
  and core resources the recommendation engine scans

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3
- An OCI account with permissions to create compute/network/IAM resources
- Either:
  - An OCI CLI config file (`oci setup config`) for API-key auth, **or**
  - `use_instance_principal = true` if running Terraform from inside OCI
    (e.g. Cloud Shell)
- An existing IAM **group** (e.g. `FinOpsViewers`) whose members will use
  the dashboard — Terraform attaches the Usage API policy to this group,
  it does not create the group itself
- An SSH key pair

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your tenancy/compartment/region/SSH key/group

terraform init
terraform plan
terraform apply
```

After apply finishes, allow 1–2 minutes for cloud-init to finish installing
dependencies, then open the URL from the `dashboard_url` output:

```bash
terraform output dashboard_url
```

## Authenticating the app itself to OCI

Terraform provisions the **infrastructure** and the IAM **policy**, but the
dashboard process on the VM still needs its own way to call the Usage API.
Two options, in order of preference:

1. **Instance Principal (recommended, no key management):** create a
   dynamic group matching this instance (e.g. by compartment OCID) and a
   policy `Allow dynamic-group <name> to read usage-report in tenancy`,
   then set the app to use instance principal auth instead of a config
   file. (Not wired up by default in `oci_finops.py` — ask if you want
   this added; it's a small change to `get_oci_config()`.)
2. **API key on the VM (default assumption in this build):** SSH in and
   run `oci setup config` as the instance's login user so
   `~/.oci/config` exists, matching how the standalone Linux/Windows
   builds authenticate.

## Key variables

| Variable | Required | Default | Notes |
|---|---|---|---|
| `region` | yes | — | e.g. `us-ashburn-1` |
| `tenancy_ocid` | yes | — | needed for the tenancy-level Usage API policy |
| `compartment_id` | yes | — | where all resources are created |
| `ssh_public_key` | yes | — | your public key contents |
| `policy_group_name` | yes | — | existing IAM group to grant Usage API access to |
| `create_network` | no | `true` | set `false` + `existing_subnet_id` to deploy into an existing VCN |
| `allowed_ingress_cidr` | no | `0.0.0.0/0` | **lock this down** for anything beyond a first test |
| `instance_shape` / `instance_ocpus` / `instance_memory_gbs` | no | E4.Flex, 2, 16 | resize as needed |
| `operating_system` / `os_version` / `instance_os_user` | no | Ubuntu 22.04 / `ubuntu` | switch all three together to use Oracle Linux + `opc` |
| `use_instance_principal` | no | `false` | set `true` to run Terraform itself from inside OCI without a config file |

See `variables.tf` for the full list with descriptions.

## Destroying

```bash
terraform destroy
```

## File layout

```
terraform/
├── providers.tf
├── variables.tf
├── network.tf                  # VCN/subnet/IGW/security list (conditional)
├── compute.tf                  # image lookup, instance, cloud-init, IAM policy
├── outputs.tf
├── cloud-init.yaml.tftpl        # bootstraps the app onto the VM
├── app-files/                   # source embedded into cloud-init at apply time
│   ├── app.py
│   ├── oci_finops.py
│   └── requirements.txt
└── terraform.tfvars.example
```

The app source lives under `app-files/` and is base64-embedded directly
into the cloud-init payload at `terraform apply` time — no external repo
or object storage bucket required, so the whole module is self-contained.
