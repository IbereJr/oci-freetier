# ----------> Compartment <----------

variable "compartment_id" {
  type    = string
}

variable "compartment_name" {
  type    = string
  default = "k8s"
}

variable "region" {
  type    = string
  default = "us-ashburn-1"
}

# ---------->VM's----------

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "ocpus_per_node" {
  type    = number
  default = 1
}

variable "memory_in_gbs_per_node" {
  type    = number
  default = 6
}

variable "image_id" {
  type    = string
  default = "ocid1.image.oc1.iad.aaaaaaaao2zpwcb2osmbtliiuzlphc3y2fqaqmcpp5ttlcf573sidkabml7a"
}
# Link to a list of available images (Be sure to select the correct region and CPU architecture. We are using Oracle-Linux-8.8-aarch64-2023.09.26-0-OKE-1.28.2-653)
# https://docs.oracle.com/en-us/iaas/images/image/d4c060a5-041c-477b-8226-2d25d91c4ffb/

# ----------> Cluster <----------
variable "k8s_version" {
  type    = string
  default = "v1.28.2"
}

variable "node_size" {
  type    = string
  default = "3"
}

variable "name" {
  type    = string
  default = "k8s"
}

# ----------> Network <----------

variable "vcn_dns_label" {
  type    = string
  default = "k8svcn"
}

# ----------> Load Balancer <----------

variable "load_balancer_name_space" {
  type    = string
  default = "loadbalancer"
}

variable "node_port_http" {
  type    = number
  default = 30080
}

variable "node_port_https" {
  type    = number
  default = 30443
}

variable "listener_port_http" {
  type    = number
  default = 80
}

variable "listener_port_https" {
  type    = number
  default = 443
}

# ----------> Auth <----------

variable "ssh_public_key" {
  type    = string
}

variable "fingerprint" {
  type    = string
}

variable "private_key_path" {
  type    = string
}

variable "tenancy_ocid" {
  type    = string
}

variable "user_ocid" {
  type    = string
}

variable "oci_profile" {
  type    = string
}
# ----------> VPN <--------

variable "timezone" {
  type    = string
  description = "Timezone."
  default = "America/Sao_Paulo"
}

variable "cpe_name" {
  default     = "cpe"
  description = "Nome do Roteador remoto da VPN."
  type        = string
}

variable "cpe_public_ip" {
  description = "IP externo do roteador remoto da VPN."
  type        = string
  default     = "none"
}

variable "cpe_private_ip" {
  default     = "10.0.0.1"
  description = "IP interno do roteador remoto da VPN."
  type        = string
}

variable "cpe_network_cidr" {
  default     = "10.0.0.0/24"
  description = "Rede interna remota."
  type        = string
}

variable "vpn_shared_secret" {
  default     = "sdalasuidyaioufybopsduivyosaid"
  type        = string
}

#----------> Instances <-----------
variable "boot_volume_size_in_gbs" {
  description = "A custom size for the boot volume. Must be between 50 and 200. If not set, defaults to the size of the image which is around 46 GB."
  default     = null

  validation {
    condition     = var.boot_volume_size_in_gbs == null ? true : var.boot_volume_size_in_gbs >= 50
    error_message = "The value of boot_volume_size_in_gbs must be greater than or equal to 50."
  }

  validation {
    condition     = var.boot_volume_size_in_gbs == null ? true : var.boot_volume_size_in_gbs <= 200
    error_message = "The value of boot_volume_size_in_gbs must be less than or equal to 200 to remain in the free tier."
  }
}

variable "hostname1" {
  description = "The hostname of the instance."
  type        = string
}

variable "hostname2" {
  description = "The hostname of the instance."
  type        = string
}

variable "operating_system" {
  description = "The Operating System of the platform image to use. Valid values are \"Canonical Ubuntu\", \"CentOS\", \"Oracle Autonomous Linux\", \"Oracle Linux\", or \"Oracle Linux Cloud Developer\""
  type        = string

  validation {
    condition     = contains(["Canonical Ubuntu", "CentOS", "Oracle Autonomous Linux", "Oracle Linux", "Oracle Linux Cloud Developer"], var.operating_system)
    error_message = "The value of operating_system must be one of \"Canonical Ubuntu\", \"CentOS\", \"Oracle Autonomous Linux\", \"Oracle Linux\", or \"Oracle Linux Cloud Developer\"."
  }
}

variable "operating_system_version" {
  description = "The version of the Operating System specified in `operating_system`."
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data passed to cloud-init when the instance is started. Defaults to `null`."
  type        = string
  default     = null
}

variable "nsg_ids" {
  description = "A list of Network Security Group OCIDs to attach to the primary vnic."
  type        = list(string)
  default     = []
}
