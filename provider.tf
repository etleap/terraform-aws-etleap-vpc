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
  default = null
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

variable "non_critial_cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to send notifications to when a Cloudwatch alarm is triggered"
}

variable "critial_cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to send notifications when critical CloudWatch alarms are triggered"
}

variable app_instance_type {
  default     = "t3.large"
  description = "The instance type for the main app node(s)"
}

variable nat_instance_type {
  default     = "m5n.large"
  description = "The instance type for the NAT instance"
}

variable dms_instance_type {
  default     = "dms.t2.small"
  description = "The instance type for the DMS instance"
}

variable dms_roles_to_be_created {
  default     = true
  description = "True if this template should create the roles required by DMS, “dms-vpc-role” and “dms-cloudwatch-logs-role”. Set to `false` if you have already used DMS in the account where you deploy Etleap."
}

variable "unique_resource_names" {
  default     = true
  description = "If set to 'true', a suffix is appended to resource names to make them unique per deployment. Recommend leaving this as 'true' except in the case of migrations from earlier versions."
}

variable "s3_input_buckets" {
  default = []
  description = "The names of the S3 buckets which will be used with \"S3 Input\" connections. The module will create an IAM role to be specified with the \"S3 Input\" connections."
}

variable "s3_data_lake_account_ids" {
  default = []
  description = "The 12-digit IDs of the AWS accounts containing the roles specified with \"S3 Data Lake\" connections. IAM roles in these accounts are given read access to the intermediate data S3 bucket."
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
    app = "ami-0c7afe61eea27e5cd"
    nat = "ami-00a9d4a05375b2763"
  }
}

provider "aws" {
  version = ">= 2.37.0"
  region  = var.region
}

locals {
  resource_name_suffix = var.unique_resource_names ? "-${var.deployment_id}-${random_id.deployment_random.hex}" : ""
}
