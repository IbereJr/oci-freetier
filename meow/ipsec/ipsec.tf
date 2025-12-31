data "oci_core_drg_route_tables" "drg_rt" {
    drg_id = var.drg_id
}

resource "oci_core_cpe" "cpe_house" {
  compartment_id = var.compartment_id
  display_name   = "${var.cpe_name} CPE"
  ip_address     = var.cpe_public_ip
}

resource "oci_core_ipsec" "ipsec" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.cpe_house.id
  drg_id         = var.drg_id
  static_routes  = [var.cpe_network_cidr]
  display_name   = "SiteToSiteVPN"
  cpe_local_identifier      = var.cpe_public_ip
  cpe_local_identifier_type = "IP_ADDRESS"
}

resource "oci_core_route_table" "vcn_route_table" {
  vcn_id         = var.vcn_id
  compartment_id = var.compartment_id
  route_rules {
    destination       = var.cpe_network_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.drg_id
  }
}

data "oci_core_ipsec_connection_tunnels" "ipsec" {
  ipsec_id = oci_core_ipsec.ipsec.id
}

resource "oci_core_ipsec_connection_tunnel_management" "onprem_ipsec_tunnel_1" {
  ipsec_id  = oci_core_ipsec.ipsec.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[0].id
  depends_on = [data.oci_core_ipsec_connection_tunnels.ipsec]
  oracle_can_initiate = "RESPONDER_ONLY"
  bgp_session_info {
       customer_interface_ip = "10.2.255.1/30"
       oracle_interface_ip = "10.2.255.2/30"
  }

  display_name  = "OnPrem-IPSec-tunnel-1"
  routing       = "STATIC"
  ike_version   = "V2"
  shared_secret = var.vpn_shared_secret
}

resource "oci_core_ipsec_connection_tunnel_management" "onprem_ipsec_tunnel_2" {
  ipsec_id  = oci_core_ipsec.ipsec.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.ipsec.ip_sec_connection_tunnels[1].id
  depends_on = [data.oci_core_ipsec_connection_tunnels.ipsec]
  oracle_can_initiate = "RESPONDER_ONLY"
  bgp_session_info {
       customer_interface_ip = "10.2.255.5/30"
       oracle_interface_ip = "10.2.255.6/30"
   }
  display_name  = "OnPrem-IPSec-tunnel-2"
  routing       = "STATIC"
  ike_version   = "V2"
  shared_secret = var.vpn_shared_secret
}
