############################
# Networking (created only when create_network = true)
############################

resource "oci_core_vcn" "finops_vcn" {
  count          = var.create_network ? 1 : 0
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "${var.instance_display_name}-vcn"
  dns_label      = "finopsvcn"
}

resource "oci_core_internet_gateway" "finops_igw" {
  count          = var.create_network ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.finops_vcn[0].id
  display_name   = "${var.instance_display_name}-igw"
  enabled        = true
}

resource "oci_core_route_table" "finops_rt" {
  count          = var.create_network ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.finops_vcn[0].id
  display_name   = "${var.instance_display_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.finops_igw[0].id
  }
}

resource "oci_core_security_list" "finops_sl" {
  count          = var.create_network ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.finops_vcn[0].id
  display_name   = "${var.instance_display_name}-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.allowed_ingress_cidr
    protocol = "6" # TCP
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    source   = var.allowed_ingress_cidr
    protocol = "6" # TCP
    tcp_options {
      min = var.dashboard_port
      max = var.dashboard_port
    }
  }
}

resource "oci_core_subnet" "finops_subnet" {
  count                      = var.create_network ? 1 : 0
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.finops_vcn[0].id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.instance_display_name}-subnet"
  dns_label                  = "finopssub"
  route_table_id             = oci_core_route_table.finops_rt[0].id
  security_list_ids          = [oci_core_security_list.finops_sl[0].id]
  prohibit_public_ip_on_vnic = false
}

locals {
  subnet_id = var.create_network ? oci_core_subnet.finops_subnet[0].id : var.existing_subnet_id
}
