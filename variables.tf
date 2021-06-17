// Configurable variables begin here
// ---------------------------------

variable "region" {
}

variable "deployment_id" {
}

variable "vpc_cidr_block_1" {
  description = "The first octet of the CIDR block of the desired VPC's address space."
  default     = 10
  validation {
    condition     = var.vpc_cidr_block_1 == 10 || var.vpc_cidr_block_1 == 172 || var.vpc_cidr_block_1 == 192
    error_message = "First octet must one of 10, 172 or 192."
  }
}

variable "vpc_cidr_block_2" {
  description = "The second octet of the CIDR block of the desired VPC's address space."
  default     = 10
  validation {
    condition     = var.vpc_cidr_block_2 >= 0 && var.vpc_cidr_block_2 <= 255
    error_message = "Second octet must be in the [0, 255] range."
  }
}

variable "vpc_cidr_block_3" {
  description = "The third octet of the CIDR block of the desired VPC's address space. Must be divisible by 4 because Etleap creates 4 /24 blocks."
  default     = 0
  validation {
    condition     = var.vpc_cidr_block_3 >= 0 && var.vpc_cidr_block_3 < 256 && var.vpc_cidr_block_3 % 4 == 0
    error_message = "Third octet must be in the [0, 255] range, and divisible by 4 to allow for a /22 VPC CIDR range."
  }
}

variable "key_name" {
}

variable "first_name" {
}

variable "last_name" {
}

variable "email" {
}

variable "extra_security_groups" {
  description = "Grant access to the DB, EC2 instance, and EMR cluster to the specified Security Groups."
  default     = []
}

variable "ssl_key" {
  default     = null
  description = "Deprecated. Private key to use for signing SSL requests. Replaced by using an ACM managed certificate."
}

variable "ssl_pem" {
  default     = null
  description = "Deprecated. Certificate to user for signing SSL requests. Replaced by using an ACM managed certificate."
}

locals {
  ssl_key = var.ssl_key == null ? file("${path.module}/ssl/key.pem") : var.ssl_key
  ssl_pem = var.ssl_pem == null ? file("${path.module}/ssl/cert.pem") : var.ssl_pem
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

variable "non_critical_cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to send notifications to when a Cloudwatch alarm is triggered"
}

variable "critical_cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to send notifications when critical CloudWatch alarms are triggered"
}

variable "app_instance_type" {
  default     = "t3.xlarge"
  description = "The instance type for the main app node(s)"
}

variable "nat_instance_type" {
  default     = "m5n.large"
  description = "The instance type for the NAT instance"
}

variable "dms_instance_type" {
  default     = "dms.t2.small"
  description = "The instance type for the DMS instance"
}

variable "dms_roles_to_be_created" {
  default     = true
  description = "True if this template should create the roles required by DMS, “dms-vpc-role” and “dms-cloudwatch-logs-role”. Set to `false` if you have already used DMS in the account where you deploy Etleap."
}

variable "unique_resource_names" {
  default     = true
  description = "If set to 'true', a suffix is appended to resource names to make them unique per deployment. Recommend leaving this as 'true' except in the case of migrations from earlier versions."
}

variable "s3_input_buckets" {
  default     = []
  description = "The names of the S3 buckets which will be used with \"S3 Input\" connections. The module will create an IAM role to be specified with the \"S3 Input\" connections."
}

variable "s3_data_lake_account_ids" {
  default     = []
  description = "The 12-digit IDs of the AWS accounts containing the roles specified with \"S3 Data Lake\" connections. IAM roles in these accounts are given read access to the intermediate data S3 bucket."
}

variable "github_username" {
  default     = null
  description = "Github username to use when accessing custom transforms"
}

variable "github_access_token_arn" {
  default     = null
  description = "ARN of the secret containing the GitHub access token"
}

variable "connection_secrets" {
  default     = {}
  description = "A map between environment variables and Secrets Manager Secret ARN for secrets to be injected into the application."
}

variable "resource_tags" {
  default     = {}
  description = "Resource tags to be applied to all resources create by this template."
  type        = map(string)
}

variable "vpc_id" {
  default     = null
  description = "Existing VPC to deploy Etleap in."
  type        = string

  validation {
    condition     = var.vpc_id == null ? true : can(regex("^vpc-", var.vpc_id))
    error_message = "Invalid VPC ID."
  }
}

variable "public_subnets" {
  default     = null
  description = "Existing public subnets to deploy Etleap in."
  type        = list(string)

  validation {
    condition = var.public_subnets == null ? true : (length(var.public_subnets) == 2 && alltrue([
      for s in var.public_subnets : can(regex("^subnet-", s))
    ]))
    error_message = "We require 2 valid public subnet ID's to be provided."
  }
}

variable "private_subnets" {
  default     = null
  description = "Existing private subnets to deploy Etleap in."
  type        = list(string)

  validation {
    condition = var.private_subnets == null ? true : (length(var.private_subnets) == 2 && alltrue([
      for s in var.private_subnets : can(regex("^subnet-", s))
    ]))
    error_message = "We require 2 valid private subnet ID's to be provided."
  }
}

variable "emr_security_configuration_name" {
  default     = null
  description = "Specify the name of the security configuration to use when creating the EMR cluster."
}

variable "s3_kms_encryption_key" {
  default     = null
  description = "The key to use to encrypt S3 objects in the intermediate bucket."
}

variable "disable_cdc_support" {
  default     = false
  description = "Set to true if this deployment will not use CDC pipelines. This will cause the DMS Replication Instance and associated resources not to be created. Defaults to false."
}

variable "app_access_cidr_blocks" {
  default     = ["0.0.0.0/0"]
  description = "CIDR ranges that have access to the application (port 443). Defaults to allowing all IP addresses."
}

variable "ssh_access_cidr_blocks" {
  default     = ["0.0.0.0/0"]
  description = "CIDR ranges that have SSH access to the application instance(s). Defaults to allowing all IP addresses."
}

variable "roles_allowed_to_be_assumed" {
  default     = ["*"]
  description = "A list of roles that can be assumed by the app. When not specified, it defaults to all roles (*)."
}

variable "enable_public_access" {
  default     = true
  description = "Enable public access to the Etleap deployment. This will place the application instance(s) in the public subnet and adding an Elastic IP for each. Defaults to true."
}

variable "acm_certificate_arn" {
  default     = null
  description = "ARN Certificate to use for SSL. If the certificate is specified, it must use either RSA_1024 or RSA_2048. See https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html for more details. If no certificate is specified, the deployment will use a default one bundled with the template."
}

variable "rds_backup_retention_period" {
  default     = 7
  description = "The number of days to retain the automated database snapshots. Defaults to 7 days."
}

# here we are validating the VPC config is valid, and that we have 4 subnets if the user is specifying a VPC ID.
locals {
  validate_vpc_cnd = var.vpc_id == null ? true : (var.public_subnets == null ? false : length(var.public_subnets) == 2) && (var.private_subnets == null ? false : length(var.private_subnets) == 2)
  validate_vpc_msg = "The VPC ID has been specified, but the public and private subnets have not."
}

resource "null_resource" "is_vpc_spec_valid" {
  count = local.validate_vpc_cnd ? 0 : local.validate_vpc_msg
}

locals {
  is_valid_10_subnet_range  = var.vpc_cidr_block_1 == 10
  is_valid_172_subnet_range = var.vpc_cidr_block_1 == 172 && var.vpc_cidr_block_2 >= 16 && var.vpc_cidr_block_2 <= 32
  is_valid_192_subnet_range = var.vpc_cidr_block_1 == 192 && var.vpc_cidr_block_2 == 168
  is_cidr_range_valid_cnd   = var.vpc_id == null ? (local.is_valid_10_subnet_range || local.is_valid_172_subnet_range || local.is_valid_192_subnet_range) : true
  is_cidr_range_valid_msg   = "CIDR blocks must be in the following ranges: 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16."
}

resource "null_resource" "are_cidr_ranges_valid" {
  count = local.is_cidr_range_valid_cnd ? 0 : local.is_cidr_range_valid_msg
}

// -----------------------------
// End of configurable variables

variable "amis" {
  default = {
    app = "ami-08ce966d848a83907"
    nat = "ami-00a9d4a05375b2763"
  }
}
