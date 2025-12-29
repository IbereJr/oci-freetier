output "instance_name" {
  value = oci_core_instance.instance.display_name
}

output "instance_public_ip" {
  value = oci_core_instance.instance.public_ip
}
