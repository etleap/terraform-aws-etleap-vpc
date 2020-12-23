// Configurable variables begin here
// ---------------------------------

variable "region" {
}

variable "deployment_id" {
}

variable "deployment_secret_arn" {
}

variable "db_root_password_arn" {
}

variable "admin_password_arn" {
}

variable "db_password_arn" {
}

variable "db_salesforce_password_arn" {
}

variable "setup_password" {
}

variable "vpc_cidr_block_1" {
  description = "The first octet of the CIDR block of the desired VPC's address space."
}

variable "vpc_cidr_block_2" {
  description = "The second octet of the CIDR block of the desired VPC's address space."
}

variable "vpc_cidr_block_3" {
  description = "The third octet of the CIDR block of the desired VPC's address space. Must be divisible by 4 because Etleap creates 4 /24 blocks."
  default     = "0"
}

variable "key_name" {
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

variable "ssl_key" {
}

variable "ssl_pem" {
}

variable "github_access_token" {
  default = ""
}

variable "app_hostname" {
  default = "$(curl -sS http://169.254.169.254/latest/meta-data/public-ipv4)"
}

variable "ha_mode" {
  default = false
} 

variable "app_private_ip" {
  default = null
}

variable "nat_private_ip" {
  default = null
}

variable "cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to send notifications to when a Cloudwatch alarm is triggered"
}

variable app_instance_type {
  default     = "t3.large"
  description = "The instance type for the main app node(s)"
}

variable nat_instance_type {
  default     = "m5n.large"
  description = "The instance type for the NAT instance"
}

// -----------------------------
// End of configurable variables

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "db_root_password" {
  arn = var.db_root_password_arn
}

data "aws_secretsmanager_secret_version" "db_root_password" {
  secret_id = data.aws_secretsmanager_secret.db_root_password.id
}

variable "amis" {
  default = {
    app = "ami-046ce6172c7e24849"
    nat = "ami-00a9d4a05375b2763"
  }
}

provider "aws" {
  version = ">= 2.37.0"
  region  = var.region
}
