# Copy this file to terraform.tfvars and fill in your own values.
# Only region, tenancy_ocid, compartment_id, ssh_public_key, and
# policy_group_name are required — everything else has a sensible default.

region          = "us-ashburn-1"
tenancy_ocid    = "ocid1.tenancy.oc1..aaaaaaaahs6wa64jvxhcf2cjtlmhpvwutxn2i42ceysl6oy35ks5fyvx6cca"
compartment_id  = "ocid1.compartment.oc1..aaaaaaaaqib2nb6ujwiv3quscqif6w3idv5rngsl45zf62l5ki2qx2dsmyba"
ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmeiZqAaayZd6dOSom4kK7cKBRvBIzNeCIvEQzmxER/uDOtctVR1zTpYK/WMsTpXafSy1mIbGKqgLg23F0tOCwdz0mFNA3d2afCQePa2rrZrIoSvrARyQjiFC43cStQ7LHBXT7nRO5l6LjzT9+sVDkw0AtdmHO7JdSK/rm0Py8iPpPy9RUySM7Zaso2gVyqGAkHYCH++tRJP8vzmGsSbbGbXKcSZpcYgmRdJCjmG36eFjpUUIm19nEZ6cFf3k7A6pnWm6onjlye8Vh1O43dn9OaIeUpfKiyhT5OjY3yncP4hoBCMrHRo521MRVV+6GkldEyJlwOakEV4CZ6jnI8Ruf ssh-key-2026-05-05"

# Name of an EXISTING IAM group in your tenancy whose members should get
# read access to the Usage API + core resources needed by the dashboard.
#policy_group_name = "FinOpsViewers"

# Optional overrides:
# instance_shape        = "VM.Standard.E5.Flex"
# instance_ocpus         = 2
# instance_memory_gbs    = 16
# operating_system       = "Canonical Ubuntu"
# os_version              = "22.04"
# instance_os_user        = "ubuntu"
# allowed_ingress_cidr    = "203.0.113.0/24"   # lock this down to your IP range
# create_network          = true
# use_instance_principal  = false
