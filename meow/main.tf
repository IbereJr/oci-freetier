data "external" "my_public_ip" {
   program = ["getip.sh"]
}

resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_id
  display_name   = "${var.name} DRG"
}

module "vcn" {
  source                            = "oracle-terraform-modules/vcn/oci"
  version                           = "3.6.0"
  compartment_id                    = var.compartment_id
  region                            = var.region

  local_peering_gateways            = null

  vcn_name                          = "${var.name}-VCN"
  vcn_dns_label                     = var.vcn_dns_label
  vcn_cidrs                         = ["10.2.0.0/16"]

  create_internet_gateway           = true
  create_nat_gateway                = true
  create_service_gateway            = true

  attached_drg_id                   = oci_core_drg.drg.id

  internet_gateway_route_rules = [{
    destination       = "192.168.15.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
    description       = "Terraformed - User added Routing Rule: To drg provided to this module."
  }]
  nat_gateway_route_rules = [{
    destination       = "192.168.15.0/24" 
    destination_type  = "CIDR_BLOCK"     
    network_entity_id = oci_core_drg.drg.id
    description       = "Terraformed - User added Routing Rule: To drg provided to this module."
  }]
}

resource "oci_core_drg_attachment" "drg_attachment" {
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.name}-DRG - VCN Attachment"

  network_details {
    id   = module.vcn.vcn_id
    type = "VCN"
  }
}

module "network" {
  source                            = "./network"
  compartment_id                    = var.compartment_id
  name                              = var.name
  vcn_id                            = module.vcn.vcn_id
  nat_route_id                      = module.vcn.nat_route_id
  ig_route_id                       = module.vcn.ig_route_id
}

module "oke" {
  source                            = "./oke"
  compartment_id                    = var.compartment_id
  name                              = var.name
  k8s_version                       = var.k8s_version
  node_size                         = var.node_size
  shape                             = var.shape
  memory_in_gbs_per_node            = var.memory_in_gbs_per_node
  ocpus_per_node                    = var.ocpus_per_node
  image_id                          = var.image_id
  ssh_public_key                    = var.ssh_public_key
  public_subnet_id                  = module.network.public_subnet_id
  vcn_id                            = module.vcn.vcn_id
  vcn_private_subnet_id             = module.network.vcn_private_subnet_id
}

module "loadbalancer" {
  source                            = "./loadbalancer"
  depends_on                        = [ module.oke, module.network, module.vcn ]
  namespace                         = var.load_balancer_name_space
  name                              = var.name
  node_pool                         = module.oke.node_pool_list
  compartment_id                    = var.compartment_id
  public_subnet_id                  = module.network.public_subnet_id
  node_size                         = var.node_size
  node_port_http                    = var.node_port_http
  node_port_https                   = var.node_port_https
  listener_port_http                = var.listener_port_http
  listener_port_https               = var.listener_port_https
}

module "kubeconfig" {
  source                            = "./kubeconfig"
  depends_on                        = [ module.loadbalancer ]
  cluster_id                        = module.oke.cluster_id
  oci_profile                       = var.oci_profile
}

module "vpn" {
  source                            = "./ipsec"
  depends_on                        = [ module.oke ]
  compartment_id                    = var.compartment_id
  name                              = var.name
  vcn_id                            = module.vcn.vcn_id 
  drg_id                            = oci_core_drg.drg.id
  vpn_shared_secret                 = var.vpn_shared_secret
  cpe_name                          = var.cpe_name
  cpe_public_ip                     = var.cpe_public_ip == "none" ? "${chomp(data.external.my_public_ip.result.ip_addr)}" : var.cpe_public_ip
  cpe_network_cidr                  = var.cpe_network_cidr
  cpe_private_ip                    = var.cpe_private_ip
}

module "instance1" {
  source                            = "./instances"
  depends_on                        = [ module.network ]
  compartment_id                    = var.compartment_id
  name                              = var.hostname1
  vcn_id                            = module.vcn.vcn_id
  ssh_public_key                    = var.ssh_public_key
  subnet_id                         = module.network.vcn_private_subnet_id
}

module "instance2" {
  source                            = "./instances"
  depends_on                        = [ module.network ]
  compartment_id                    = var.compartment_id
  name                              = var.hostname2
  vcn_id                            = module.vcn.vcn_id
  ssh_public_key                    = var.ssh_public_key
  subnet_id                         = module.network.vcn_private_subnet_id
}

output "instance1_name" {
  value = module.instance1.instance_name
}
output "instance1_ip" {
  value = module.instance1.instance_ip
}
output "instance2_name" {
  value = module.instance2.instance_name
}
output "instance2_ip" {
  value = module.instance2.instance_ip
}
output "public_ip" {
  value = module.loadbalancer.load_balancer_public_ip
}

output "DRG_Routes" {
   value = module.vpn.DRG_Routes
}

output "tunnels" {
  value = module.vpn.tunnels
}




