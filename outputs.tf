output "instance_public_ip" {
  description = "Public IP of the FinOps Monitor instance (if assign_public_ip = true)."
  value       = var.assign_public_ip ? oci_core_instance.finops_monitor.public_ip : null
}

output "instance_private_ip" {
  description = "Private IP of the FinOps Monitor instance."
  value       = oci_core_instance.finops_monitor.private_ip
}

output "dashboard_url" {
  description = "URL to reach the dashboard once cloud-init finishes (allow a couple of minutes after apply)."
  value = var.assign_public_ip ? (
    "http://${oci_core_instance.finops_monitor.public_ip}:${var.dashboard_port}"
  ) : "Dashboard has no public IP; reach it via ${oci_core_instance.finops_monitor.private_ip}:${var.dashboard_port} through a VPN/bastion."
}

output "ssh_command" {
  description = "SSH command to connect to the instance."
  value       = var.assign_public_ip ? "ssh ${var.instance_os_user}@${oci_core_instance.finops_monitor.public_ip}" : "Instance has no public IP — connect via bastion/VPN to ${oci_core_instance.finops_monitor.private_ip}"
}

output "instance_id" {
  description = "OCID of the created compute instance."
  value       = oci_core_instance.finops_monitor.id
}
