data "oci_identity_availability_domains" "ads" {
   compartment_id = var.compartment_id
}

data "oci_core_images" "latest_image" {
   compartment_id = var.compartment_id
   operating_system = "Canonical Ubuntu"
   operating_system_version = "24.04 Minimal"
   shape = "VM.Standard.E2.1.Micro"
}


resource "oci_core_network_security_group" "instance_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name = "NSG - Instances"
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.instance_nsg.id

  direction   = "EGRESS"
  protocol    = "all"
  destination = "0.0.0.0/0"

}

# Allow SSH (TCP port 22) Ingress traffic from any network
resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.instance_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# Allow HTTPS (TCP port 443) Ingress traffic from any network
resource "oci_core_network_security_group_security_rule" "ingress_https" {
  network_security_group_id = oci_core_network_security_group.instance_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# Allow HTTP (TCP port 80) Ingress traffic from any network
resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.instance_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# Allow ANY Ingress traffic from within simple vcn
resource "oci_core_network_security_group_security_rule" "ingress_all" {
  network_security_group_id = oci_core_network_security_group.instance_nsg.id
  protocol                  = "all"
  direction                 = "INGRESS"
  source                    = "0.0.0.0/0"
  stateless                 = false
}



resource "oci_core_instance" "instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = var.name
  shape               = "VM.Standard.E2.1.Micro"
  source_details {
     is_preserve_boot_volume_enabled = false
     source_id = data.oci_core_images.latest_image.images[0].id
     source_type = "image"
  }
 
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
  }
  preserve_boot_volume = false

  create_vnic_details {
    assign_public_ip = false
    subnet_id        = var.subnet_id
    nsg_ids = [ oci_core_network_security_group.instance_nsg.id ]
  }
}


resource "null_resource" "atuaz_sshconfig" {
  provisioner "local-exec" {
      command = "sudo sed -i '/${var.name}\\s+/c${oci_core_instance.instance.public_ip}\t${var.name}' /etc/hosts"
  }
}
