output "public_ip" {
  description = "Public IP of the compute instance"
  value       = oci_core_instance.vm.public_ip
}

output "private_ip" {
  description = "Private IP of the compute instance"
  value       = oci_core_instance.vm.private_ip
}

output "instance_ocid" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.vm.id
}

output "nsg_ocid" {
  description = "OCID of the Network Security Group"
  value       = oci_core_network_security_group.app_nsg.id
}

output "subnet_ocid" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public.id
}
