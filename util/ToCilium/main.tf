locals {
  max_cores_free_tier     = 4
  max_memory_free_tier_gb = 24
}

#resource "oci_identity_compartment" "compartment" {
#  name          = var.name
#  description   = "Compartment for the Oracle Cloud Always Free."
#  enable_delete = true
#}

module "oke_cluster" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "5.3.3"
  providers = { oci.home = oci.home }

  # Required inputs (replace with your specific values)
  compartment_id       = var.compartment_id
  tenancy_id           = var.tenancy_id
  user_id              = var.user_id
  home_region          = var.home_region
  api_fingerprint      = var.api_fingerprint
  api_private_key_path = var.api_private_key_path
  
  # Network config
  create_vcn               = true
  vcn_dns_label            = "meow"
  vcn_name                 = "Meow VCN"
  assign_dns               = true
  load_balancers           = "public"
  preferred_load_balancer  = "public"
  lockdown_default_seclist = true
  vcn_cidrs                = ["10.2.0.0/16"]
  subnets = {
    bastion  = { newbits = 13, netnum = 0, dns_label = "bastion", create="always" }
    cp       = { newbits = 13, netnum = 2, dns_label = "cp", create="always" }
    pub_lb   = { newbits = 11, netnum = 17, dns_label = "plb", create="always" }
    workers  = { newbits = 2, netnum = 1, dns_label = "workers", create="always" }
    pods     = { newbits = 2, netnum = 2, dns_label = "pods", create="always" }
  }


  # Cluster configuration (example values)
  cluster_name       = var.name
  kubernetes_version = "v1.34.1"
  create_operator    = false
  allow_bastion_cluster_access = true
  #bastion_upgrade = [ "vim" ]
  bastion_await_cloudinit = false
  ssh_public_key = file("~/.ssh/ibereoci.pub")
  ssh_private_key = file("~/.ssh/ibereoci")
  #control_plane_is_public = true
  #assign_public_ip_to_control_plane = true
  #control_plane_allowed_cidrs = [ "0.0.0.0/0" ]

  #Bastion
  create_bastion              = true
  bastion_allowed_cidrs = [ "0.0.0.0/0" ]
  bastion_availability_domain = null
  bastion_image_type          = "custom"
  bastion_image_id            = "ocid1.image.oc1.sa-vinhedo-1.aaaaaaaallj73rbis6lzsyvflgys7mep7svqjzllnwfmkacimuvtq5rrcbua"
  bastion_upgrade             = true
  bastion_user                = "ubuntu"

  bastion_shape = {
    shape                     = "VM.Standard.E2.1.Micro"
  }

  worker_pool_mode = "node-pool"
  worker_pool_size = var.node_pool_size
  worker_pools = {
      ampere-a1-free-tier = {
        shape            = "VM.Standard.A1.Flex",
        ocpus            = local.max_cores_free_tier / var.node_pool_size,
        memory           = local.max_memory_free_tier_gb / var.node_pool_size,
        node_pool_size   = var.node_pool_size,
        boot_volume_size = 75,
        label            = {
          pool         = "arm-ampere-a1-free-tier",
          architecture = "arm",
          pool-type    = "free-tier",
          processor    = "ampere-a1",
          shape        = "VM.Standard.A1.Flex",
          region       = var.home_region
        }
      }
  }
  create_cluster = true 
}

data "oci_core_network_security_group" "nsg_bastion" {
  network_security_group_id = module.oke_cluster.bastion_nsg_id
}

resource "oci_core_network_security_group_security_rule" "access_to_internet" {
  network_security_group_id = data.oci_core_network_security_group.nsg_bastion.id
  direction = "EGRESS"
  destination_type = "CIDR_BLOCK"
  destination = "0.0.0.0/0"
  protocol = "all"
  description = "Allow Outgoing"
}

resource "terraform_data" "data_bastion" {
  input = module.oke_cluster.bastion_public_ip
}

resource "null_resource" "install_in_bastion" {
  depends_on = [module.oke_cluster]
  #count = var.await_cloudinit ? 1 : 0

  connection {
    host        = module.oke_cluster.bastion_public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/ibereoci")
    timeout     = "40m"
    type        = "ssh"
  }

  lifecycle {
    replace_triggered_by = [ terraform_data.data_bastion ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt  install -y curl vim wireguard gpg apt-transport-https",
      "curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null",
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "chmod 755 kubectl",
      "sudo mv kubectl /usr/local/bin",
      "curl -o install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh",
      "bash ./install.sh --accept-all-defaults --update-path-and-enable-tab-completion --rc-file-path $HOME/.bashrc",
      "mkdir -p ~/.oci",
      "mkdir -p ~/.kube",
      "echo deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list",
      "sudo apt-get update",
      "sudo apt-get -y install helm",
      "wg genkey | sudo tee /etc/wireguard/private.key",
      "sudo chmod go= /etc/wireguard/private.key",
      "sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key"
    ]
  }
  provisioner "file" {
    source      = "~/.oci/config"
    destination = "/home/ubuntu/.oci/config"
  }
  provisioner "file" {
    source      = "~/.ssh/ibere"
    destination = "/home/ubuntu/.ssh/ibere"
  }
  provisioner "file" {
    source      = "cilium.yaml"
    destination = "/home/ubuntu/cilium.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.oci/config",
      "chmod 600 /home/ubuntu/.ssh/ibere",
      "sleep 50",
      "/home/ubuntu/bin/oci ce cluster create-kubeconfig --cluster-id ${module.oke_cluster.cluster_id} --file $HOME/.kube/config --region ${var.region}",
      "chmod 600 /home/ubuntu/.kube/config",
      "helm repo add cilium https://helm.cilium.io/",
      "export VERSION=v0.18.9",
      "curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$VERSION/cilium-linux-amd64.tar.gz",
      "sudo tar xzvf cilium-linux-amd64.tar.gz -C /usr/local/bin",
      "helm install cilium cilium/cilium --namespace=kube-system -f cilium.yaml",
      "sleep 10 && kubectl -n kube-system delete ds kube-flannel-ds",
      "sleep 6 && kubectl -n kube-system delete pod -l k8s-app=clustermesh-apiserver",
      "sleep 2 && kubectl -n kube-system delete pod -l k8s-app=hubble-relay",
      "sleep 1 && kubectl -n kube-system delete pod -l k8s-app=hubble-ui"
    ]
  }
}


#resource "oci_core_drg" "drg" {
#  compartment_id = var.compartment_id
#  display_name   = "${upper(var.name)} DRG"
#}
#
## 2. Attach the DRG to your VCN
#resource "oci_core_drg_attachment" "drg_attachment" {
#  drg_id       = oci_core_drg.drg.id
#  network_details {
#    id   = module.oke_cluster.vcn_id
#    type = "VCN"
#  }
#}
#
## 3. Create a Customer Premises Equipment (CPE) object
#resource "oci_core_cpe" "cpe_house" {
#  compartment_id = var.compartment_id
#  display_name   = var.cpe_name
#  ip_address     = var.cpe_public_ip
#}
#
## 4. Create the IPSec connection (Site-to-Site VPN)
#resource "oci_core_ipsec" "ipsec" {
#  compartment_id = var.compartment_id
#  cpe_id         = oci_core_cpe.cpe_house.id
#  drg_id         = oci_core_drg.drg.id
#  static_routes  = [var.cpe_network_cidr] # Specify the remote network routes
#  display_name   = "SiteToSiteVPN"
#  cpe_local_identifier      = var.cpe_private_ip
#  cpe_local_identifier_type = "IP_ADDRESS"
#}

# 5. Update VCN route tables to direct on-premises traffic to the DRG
# You must configure your VCN's route tables to send traffic destined for the 
# on-premises CIDR block to the DRG attachment.

#resource "oci_core_route_table" "vcn_route_table" {
#  vcn_id         = module.oke_cluster.vcn_id
#  compartment_id = var.compartment_id
#  route_rules {
#    destination       = var.cpe_network_cidr
#    destination_type  = "CIDR_BLOCK"
#    network_entity_id = oci_core_drg_attachment.drg_attachment.id
#  }
#}


# Example Output to get cluster details after creation
output "cluster_id" {
  value = module.oke_cluster.cluster_id
}

output "BastionIP" {
    value = module.oke_cluster.bastion_public_ip
}
