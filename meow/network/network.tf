resource "oci_core_security_list" "private_subnet_sl" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id

  display_name = "${var.name}-private-subnet-sl"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }
}

resource "oci_core_security_list" "public_subnet_sl" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id

  display_name = "${var.name}-public-subnet-sl"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.2.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      max = 80
      min = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_security_list" "vpn_sl" {
    compartment_id = var.compartment_id
    vcn_id = var.vcn_id

    display_name = "Security List VPN"
  egress_security_rules {
      destination = "0.0.0.0/0"
      protocol = "all"
  }
  ingress_security_rules {
      protocol = "1"
      source = "0.0.0.0/0"
      icmp_options {
            type = 3
            code = 4
      }
  }

	ingress_security_rules {
      protocol = "all"
      source = "192.168.15.0/24"
  }

	ingress_security_rules {
       protocol = "6"
       source = "0.0.0.0/0"
       tcp_options {
            max = 443
            min = 443
       }
    }

	ingress_security_rules {
       protocol = "6"
       source = "0.0.0.0/0"
       tcp_options {
            max = 22
            min = 22
       }
    }

}


resource "oci_core_subnet" "vcn_private_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  cidr_block     = "10.2.1.0/24"

  route_table_id             = var.nat_route_id
  security_list_ids          = [oci_core_security_list.private_subnet_sl.id,oci_core_security_list.vpn_sl.id]
  display_name               = "${var.name}-private-subnet"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "vcn_public_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  cidr_block     = "10.2.0.0/24"

  route_table_id    = var.ig_route_id
  security_list_ids = [oci_core_security_list.public_subnet_sl.id,oci_core_security_list.vpn_sl.id]
  display_name      = "${var.name}-public-subnet"
}

