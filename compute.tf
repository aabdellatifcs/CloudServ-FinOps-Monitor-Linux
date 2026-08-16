############################
# Availability domain lookup
############################

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[
    var.availability_domain_number - 1
  ].name
}

############################
# Image lookup (works for any tenancy/region — no hardcoded OCID)
############################

data "oci_core_images" "base_image" {
  compartment_id           = var.compartment_id
  operating_system         = var.operating_system
  operating_system_version = var.os_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  image_id = data.oci_core_images.base_image.images[0].id
}

############################
# Cloud-init rendering
############################

locals {
  cloud_init_rendered = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    app_py_b64           = filebase64("${path.module}/app-files/app.py")
    oci_finops_py_b64    = filebase64("${path.module}/app-files/oci_finops.py")
    requirements_txt_b64 = filebase64("${path.module}/app-files/requirements.txt")
    dashboard_port       = var.dashboard_port
    os_user              = var.instance_os_user
  })
}

############################
# Compute instance
############################

resource "time_sleep" "wait_for_policy_propagation" {
  count           = var.create_usage_api_policy ? 1 : 0
  depends_on      = [oci_identity_policy.finops_usage_policy]
  create_duration = "60s"
}

resource "oci_core_instance" "finops_monitor" {
  depends_on          = [time_sleep.wait_for_policy_propagation]
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = var.instance_display_name
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gbs
  }

  create_vnic_details {
    subnet_id        = local.subnet_id
    assign_public_ip = var.assign_public_ip
  }

  source_details {
    source_type = "image"
    source_id   = local.image_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init_rendered)
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id] # avoid recreation on new image releases
  }
}

############################
# IAM policy for Usage API access
############################

resource "oci_identity_policy" "finops_usage_policy" {
  count          = var.create_usage_api_policy ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.instance_display_name}-usage-policy"
  description    = "Read access to Usage API and core resources for the OCI FinOps Monitor dashboard."

  statements = [
    "Allow group ${var.policy_group_name} to read usage-report in tenancy",
    "Allow group ${var.policy_group_name} to inspect compartments in tenancy",
    "Allow group ${var.policy_group_name} to read instances in tenancy",
    "Allow group ${var.policy_group_name} to read volumes in tenancy",
    "Allow group ${var.policy_group_name} to read volume-attachments in tenancy",
    "Allow group ${var.policy_group_name} to manage instance-family in tenancy",
    "Allow group ${var.policy_group_name} to use virtual-network-family in tenancy",
    "Allow group ${var.policy_group_name} to use volume-family in tenancy",
    "Allow group ${var.policy_group_name} to read app-catalog-listing in tenancy",
  ]
}