variable "FOUNDRY_ADMIN_KEY" {
  type      = string
  sensitive = true
}

variable "FOUNDRY_PASSWORD" {
  type      = string
  sensitive = true
}

variable "FOUNDRY_USERNAME" {
  type      = string
  sensitive = true
}

variable "FOUNDRY_LICENSE_KEY" {
  type      = string
  sensitive = true
}

locals {
  env_prefix     = "mowen-foundry-"
  region         = "UK South"
  storage_prefix = "mowenfoundry"
  dns_name       = "foundry.martowen.com"
}
