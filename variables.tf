############################
# Authentication / region
############################

variable "region" {
  description = "OCI region to deploy into, e.g. us-ashburn-1, uk-london-1, ap-mumbai-1."
  type        = string
}

variable "use_instance_principal" {
  description = "Set true to authenticate via instance principal (e.g. running Terraform from OCI Cloud Shell or a bastion instance). Set false to use a local API key / OCI CLI config file."
  type        = bool
  default     = false
}

variable "config_file_profile" {
  description = "Profile name inside ~/.oci/config to use when use_instance_principal = false."
  type        = string
  default     = "DEFAULT"
}

variable "tenancy_ocid" {
  description = "OCID of the tenancy. Required for the Usage API IAM policy this module creates."
  type        = string
}

variable "compartment_id" {
  description = "OCID of the compartment to deploy all resources into."
  type        = string
}

############################
# Networking
############################

variable "create_network" {
  description = "If true (default), this module creates its own VCN/subnet/internet gateway/security list. Set false to deploy into an existing subnet via existing_subnet_id."
  type        = bool
  default     = true
}

variable "existing_subnet_id" {
  description = "OCID of an existing public subnet to use when create_network = false."
  type        = string
  default     = null
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN this module creates (only used when create_network = true)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet this module creates (only used when create_network = true)."
  type        = string
  default     = "10.20.0.0/24"
}

variable "allowed_ingress_cidr" {
  description = "CIDR range allowed to reach the dashboard (port 8501) and SSH (port 22). Restrict this to your office/VPN range in production — 0.0.0.0/0 is convenient for a first run only."
  type        = string
  default     = "0.0.0.0/0"
}

############################
# Compute
############################

variable "availability_domain_number" {
  description = "Which availability domain to use (1, 2, or 3). The module looks up the AD list for the region and picks this index."
  type        = number
  default     = 1
}

variable "instance_shape" {
  description = "Compute shape for the VM. Flex shapes require ocpus/memory_in_gbs below."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "instance_ocpus" {
  description = "OCPUs for the flex shape."
  type        = number
  default     = 2
}

variable "instance_memory_gbs" {
  description = "Memory (GB) for the flex shape."
  type        = number
  default     = 16
}

variable "operating_system" {
  description = "Base image OS. Supported: 'Canonical Ubuntu' or 'Oracle Linux'."
  type        = string
  default     = "Oracle Linux"
}

variable "os_version" {
  description = "OS version to match against available images, e.g. '22.04' for Ubuntu or '8' for Oracle Linux."
  type        = string
  default     = "8"
}

variable "instance_os_user" {
  description = "Default login user baked into the chosen image. Use 'ubuntu' for Canonical Ubuntu images or 'opc' for Oracle Linux images — must match operating_system above."
  type        = string
  default     = "opc"
}

variable "ssh_public_key" {
  description = "Your SSH public key contents (e.g. contents of ~/.ssh/id_rsa.pub), used to log into the instance."
  type        = string
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the instance so the dashboard is reachable without a bastion/VPN."
  type        = bool
  default     = true
}

############################
# App-level
############################

variable "dashboard_port" {
  description = "Port the Streamlit dashboard listens on."
  type        = number
  default     = 8501
}

variable "instance_display_name" {
  description = "Display name for the compute instance."
  type        = string
  default     = "oci-finops-monitor"
}

variable "create_usage_api_policy" {
  description = "If true, creates an IAM policy granting this compartment's dynamic group nothing extra — instead grants the group defined by policy_group_name read access to usage-report and core resources at the tenancy level, which the Usage API requires. Set false if your tenancy already has an equivalent policy and you don't want a duplicate."
  type        = bool
  default     = true
}

variable "policy_group_name" {
  description = "Name of the existing IAM group whose members will run/use the FinOps dashboard and need Usage API read access. The group must already exist in your tenancy."
  type        = string
}
