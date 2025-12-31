output "instance_name" {
  value = oci_core_instance.instance.display_name
}

output "instance_ip" {
  value = oci_core_instance.instance.private_ip
}
