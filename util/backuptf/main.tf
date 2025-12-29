provider "oci" {
  user_ocid        = var.user_ocid        # IAM User OCID for API authentication
  fingerprint      = var.fingerprint      # API key fingerprint
  private_key_path = var.private_key_path # Path to API signing key
  tenancy_ocid     = var.tenancy_ocid     # Target tenancy OCID
  region           = var.region           # OCI region for resource management
}

provider "oci" {
  alias            = "home"
  user_ocid        = var.user_ocid        # IAM User OCID for API authentication
  fingerprint      = var.fingerprint      # API key fingerprint
  private_key_path = var.private_key_path # Path to API signing key
  tenancy_ocid     = var.tenancy_ocid     # Target tenancy OCID
  region           = var.region      # OCI region for resource management
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

