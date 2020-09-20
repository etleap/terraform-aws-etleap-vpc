// Configurable variables begin here
// ---------------------------------

variable "region" {
}

variable "deployment_id" {
}

variable "deployment_secret_arn" {
}

variable "vpc_cidr_block_1" {
}

variable "vpc_cidr_block_2" {
}

variable "subdomain" {
}

variable "route53_zone_id" {
}

variable "public_key" {
}

variable "first_name" {
}

variable "last_name" {
}

variable "email" {
}

variable "vpn_cidr_block" {
  default = "0.0.0.0/32"
}

variable "root_db_password" {
}

variable "etleap_admin_password" {
}

variable "self_signed_cert_key" {
}

variable "self_signed_cert_pem" {
}

variable "github_access_token" {
  default = ""
}

// -----------------------------
// End of configurable variables

data "aws_caller_identity" "current" {}

variable "amis" {
  default = {
    app          = "ami-046ce6172c7e24849"
    nat          = "ami-00a9d4a05375b2763"
  }
}

provider "aws" {
  version = ">= 2.37.0"
  region  = var.region
}
