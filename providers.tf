terraform {
  required_version = ">= 1.3.0"

required_providers {
  oci = {
    source  = "oracle/oci"
    version = ">= 5.0.0"
  }
  }
}

# Authentication method is controlled entirely by variables so this module
# runs unmodified for anybody, regardless of how they authenticate to OCI:
#   - API key file (default, matches `oci setup config`)
#   - Instance principal (set use_instance_principal = true when running
#     this from inside OCI, e.g. Cloud Shell or a bastion instance)
provider "oci" {
  auth                = var.use_instance_principal ? "InstancePrincipal" : "ApiKey"
  region              = var.region
  config_file_profile = var.use_instance_principal ? null : var.config_file_profile
}