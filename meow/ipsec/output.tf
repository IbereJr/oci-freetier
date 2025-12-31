output "DRG_Routes" {
   value = data.oci_core_drg_route_tables.drg_rt
}

output "tunnels" {
  description = "The public IP addresses of the OCI IPSec tunnels"
  value = {
      display_name                = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].display_name
      cpe_ip                      = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].cpe_ip
      vpn_ip                      = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].vpn_ip
      ike_version                 = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].ike_version
      nat_translation_enabled     = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].nat_translation_enabled
      oracle_can_initiate         = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].oracle_can_initiate
      status                      = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[*].status
  }
}
