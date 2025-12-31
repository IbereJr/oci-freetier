# The OCID of your OCI tenancy where resources will be managed
variable "name" {
  description = "Nome do Compartment"
  type        = string
  default     = "ocid1.compartment.oc1..aaaaaaaa............"
}

variable "tenancy_ocid" {
  description = "Tenancy OCID for your Oracle Cloud tenancy."
  type        = string
  default     = "ocid1.tenancy.oc1..aaaaaaaa............"
}

# The OCID of the IAM user for Terraform operations
variable "user_ocid" {
  description = "User OCID used for managing resources in the tenancy."
  type        = string
}

# The fingerprint of the API signing key for Oracle Cloud authentication
variable "fingerprint" {
  description = "Fingerprint of the OCI API private key."
  type        = string
}

# Filesystem path to the OCI API private key used for signing API requests
variable "private_key_path" {
  description = "Local path to the OCI API private key file."
  type        = string
}

# The OCI region (e.g., us-ashburn-1) for resource creation
variable "home_region" {
  description = "OCI Home region identifier (e.g., us-ashburn-1)."
  type        = string
  default     = "us-ashburn-1"
}

# The OCI region (e.g., us-ashburn-1) for resource creation
variable "region" {
  description = "OCI region identifier (e.g., us-ashburn-1)."
  type        = string
  default     = "us-ashburn-1"
}

variable "budget" {
  description = "Valor Máximo previsto de gastos em reais por mês."
  type        = number
  default     = 50
}
variable "emails" {
  description = "Lista de Emails para estouro de gastos / avisos em geral"
  type        = string
  default     = ""
}
