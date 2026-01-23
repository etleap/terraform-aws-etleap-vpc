// Configurable variables begin here
// ---------------------------------

variable "deployment_id" {
  description = "The Deployment ID for this deployment. If you don't have one, please contact Etleap Support."

  validation {
    condition     = length(var.deployment_id) <= 25
    error_message = "The variable deployment ID must be 25 characters or fewer."
  }
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
  description = "The AWS Key Pair to use for SSH access into the EC2 instances."
}

variable "first_name" {
  description = "The first name to use when creating the first Etleap user account."
}

variable "last_name" {
  description = "The last name to use when creating the first Etleap user account."
}

variable "email" {
  description = "The email to use when creating the first Etleap user account."
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

variable "app_hostname" {
  default     = null
  description = "The hostname where Etleap will be accessible from."
}

variable "app_available" {
  default     = true
  description = "Only use this if instructed by ETLeap support. Enable or disable to start or destroy the app instance."
}

variable "ha_mode" {
  default     = false
  description = "Enables High Availability mode. This will run two redundant Etleap instances in 2 availability zones, and set the RDS instace to \"multi-az\" mode."
}

variable "app_private_ip" {
  default     = null
  description = "The Private IP for the main application instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP."
}

variable "nat_private_ip" {
  default     = null
  description = "The Private IP for the NAT instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP."
}

variable "secondary_app_private_ip" {
  default     = null
  description = "The Private IP for the seconday application instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP."
}

variable "non_critical_cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to notify when non critical alarms are triggered. For the list of non-critical alarms, see _CloudWatch Alarms_ under _Monitoring and operation_ in the README."
}

variable "critical_cloudwatch_alarm_sns_topics" {
  default     = null
  description = "A list of SNS topics to notify when critical alarms are triggered. For the list of critical alarms, see _CloudWatch Alarms_ under _Monitoring and operation_ in the README."
}

variable "app_instance_type" {
  default     = "t3.xlarge"
  description = "The instance type for the main app node(s). Defaults to `t3.xlarge`. We do not recommend using a smaller instance type."
}

variable "nat_instance_type" {
  default     = "m5n.large"
  description = "The instance type for the NAT instance. Defaults to `m5n.large`"
}

variable "rds_instance_type" {
  default     = "db.m5.large"
  description = "The instance type for the RDS instance. Defaults to `db.m5.large`. We do not recommend using a smaller instance type."
}

variable "dms_instance_type" {
  default     = "dms.t3.small"
  description = "The instance type for the DMS instance. Defaults to `dms.t3.small`. Not used if `disable_cdc_support` is set to `true`."
}

variable "dms_roles_to_be_created" {
  default     = true
  description = "Set to `true` if this template should create the roles required by DMS, `dms-vpc-role` and `dms-cloudwatch-logs-role`. Set to `false` if are already using DMS in the account where you deploy Etleap."
}

variable "unique_resource_names" {
  default     = true
  description = "If set to 'true', a suffix is appended to resource names to make them unique per deployment. Recommend leaving this as 'true' except in the case of migrations from earlier versions."
}

variable "s3_input_buckets" {
  default     = []
  description = "The names of the S3 buckets which will be used with \"S3 Input\" connections. The module will create an IAM role to be specified with the \"S3 Input\" connections, together with a bucket policy that needs to be applied to the bucket."
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
  description = "A map between environment variables and Secrets Manager Secret ARN for secrets to be injected into the application. This is only used for enabling certain integrations."
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
    condition = var.public_subnets == null ? true : (length(var.public_subnets) == 3 && alltrue([
      for s in var.public_subnets : can(regex("^subnet-", s))
    ]))
    error_message = "We require 3 valid public subnet ID's to be provided."
  }
}

variable "private_subnets" {
  default     = null
  description = "Existing private subnets to deploy Etleap in."
  type        = list(string)

  validation {
    condition = var.private_subnets == null ? true : (length(var.private_subnets) == 3 && alltrue([
      for s in var.private_subnets : can(regex("^subnet-", s))
    ]))
    error_message = "We require 3 valid private subnet ID's to be provided."
  }
}

variable "s3_kms_encryption_key" {
  default     = null
  description = "The ARN of an AWS KMS key to use to encrypt S3 objects in the intermediate bucket. If not specified, server-side encryption with Amazon S3-managed keys (SSE-S3) will be used."
}

variable "emr_kms_encryption_key" {
  default     = null
  description = "The ARN of an AWS KMS key to use to encrypt the local disk for EMR nodes. If not specified, a new KMS key will be created."
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
  description = "A list of external roles that can be assumed by the app. When not specified, it defaults to all roles (*)."
}

variable "enable_public_access" {
  default     = true
  description = "Enable public access to the Etleap deployment. This will create an _Internet facing_ ALB."
}

variable "acm_certificate_arn" {
  default     = null
  description = "ARN Certificate to use for SSL connections to the Etleap UI. If the certificate is specified, it must use either RSA_1024 or RSA_2048. See https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html for more details. If no certificate is specified, the deployment will use a default one bundled with the template."
}

variable "rds_backup_retention_period" {
  default     = 7
  description = "The number of days to retain the automated database snapshots. Defaults to 7 days."
}

variable "rds_allow_major_version_upgrade" {
  default     = false
  description = "Only use this if instructed by ETLeap support. Indicates that major version upgrades are allowed."
}

variable "rds_apply_immediately" {
  default     = false
  description = "If any RDS modifications are required they will be applied immediately instead of during the next maintenance window. It is recommended to set this back to `false` once the change has been applied."
}

variable "emr_core_node_count" {
  default     = 1
  description = "The number of EMR core nodes in the EMR cluster. Defaults to 1."
}

variable "allow_iam_devops_role" {
  default     = false
  description = "Enable access to the deployment for Etleap by creating an IAM role that Etleap's ops team can assume."
}

variable "allow_iam_support_role" {
  default     = true
  description = "Enables access to the deployment for Etleap by creating an IAM role that Etleap's support team can assume along with limited IAM policies for providing support."
}

variable "enable_streaming_ingestion" {
  default     = false
  description = "Enable support and required infrastructure for streaming ingestion sources."
}

variable "streaming_endpoint_hostname" {
  default     = null
  description = "The hostname the streaming ingestion webhook will be accessible from. Only has an effect if `enable_streaming_ingestion` is set to `true`."
}

variable "streaming_endpoint_acm_certificate_arn" {
  default     = null
  description = "ARN Certificate to use for SSL connections to the streaming ingestion webhook. If the certificate is specified, it must use either RSA_1024 or RSA_2048. See https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html for more details. If no certificate is specified, the deployment will use a default one bundled with the template."
}

variable "streaming_endpoint_access_cidr_blocks" {
  default     = ["0.0.0.0/0"]
  description = "CIDR ranges that have access to the streaming ingestion webhook (both HTTP and HTTPS). Defaults to allowing all IP addresses."
}

variable "emr_instance_fleet_smallest_instance_size" {
  type        = string
  default     = "xlarge"
  description = "The smallest instance size used for EMR instance fleet. The instance fleet uses sizes from the specified size up to `4xlarge` of various instance types to maximize spot instance availability. Valid values are `xlarge` and `4xlarge`, and the default is `xlarge`. Setting to `4xlarge` reduces the number of instances, which is helpful when the number of IP addresses is limited, but may also increase AWS costs for small deployments due to the lower cluster scaling granularity."

  validation {
    condition     = contains(["xlarge", "4xlarge"], var.emr_instance_fleet_smallest_instance_size)
    error_message = "Valid values are 'xlarge' or '4xlarge'."
  }
}

variable "dms_proxy_bucket" {
  default     = null
  description = "(Internal) A bucket to be used as a proxy for DMS. Should only be set in multitenant environments."
}

variable "enable_emr_preemption" {
  default     = true
  description = "(Internal) True if preemption should be enabled for the deployment's EMR cluster. Only change from the default value if requested by Etleap's support team, as it may negatively affect data processing times."
}

variable "is_influx_db_in_secondary_region" {
  default     = false
  description = "Set to true if the AWS region where you're deploying Etleap does not support Amazon Timestream for InfluxDB, and InfluxDB has therefore been created in a secondary AWS region. See the README for instructions for how to configure this."
}

variable "influx_db_hostname" {
  default     = null
  description = "The hostname of the InfluxDB instance if it is deployed in a secondary region. See `is_influx_db_in_secondary_region`."
}

variable "influx_db_password_arn" {
  default     = null
  description = "The password ARN of the InfluxDB instance if it is deployed in a secondary region. See `is_influx_db_in_secondary_region`."
}

variable "disable_cognito_identity_pool" {
  default     = false
  description = "(Internal) Set to true to disable creation of the Cognito Identity Pool for Azure Entra ID federation. This will prevent Azure Blob Storage connections from working. Only change from the default value if requested by Etleap's support team."
}

variable "outbound_access_destinations" {
  default = [{
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
    protocol   = "-1"
  }]
  type = list(map(string))

  validation {
    condition = alltrue([
      // The expression is: contains(keys(d), "cidr_block") XOR contains(keys(d), "security_group_id")
      // TF doesn't have XOR, so use equivalent NOT/AND/OR expression
      for d in var.outbound_access_destinations : !(contains(keys(d), "cidr_block") && contains(keys(d), "target_security_group_id")) && (contains(keys(d), "cidr_block") || contains(keys(d), "target_security_group_id"))
    ])
    error_message = "Exactly one of `cidr_block` and `target_security_group_id` must be specified."
  }

  description = "(Optional) Restrict outbound access for the deployment to the specified list of CIDR blocks or security groups, ports and protocols. If unspecified, this will default to the `0.0.0.0/0' CIDR block, and all ports and protocols. See the Readme section for details about the usage of this argument: https://registry.terraform.io/modules/etleap/etleap-vpc/aws/latest#restricting-outbound-access."
}

variable "kms_key_additional_policies" {
  default = []
  type = list(object({
    Sid       = optional(string)
    Effect    = string
    Action    = list(string)
    Principal = map(string)
    Resource  = string
    Condition = optional(map(any))
  }))

  validation {
    condition = alltrue([
      for policy in var.kms_key_additional_policies : (policy.Effect == "Allow" || policy.Effect == "Deny" && length(policy.Action) > 0 && length(policy.Principal) > 0 && length(policy.Resource) > 0)
    ])
    error_message = "Each policy in 'kms_key_additional_policies' must specify 'Effect', 'Action', 'Principal', and 'Resource'. 'Sid' and 'Condition' are optional."
  }

  description = "(Optional) List of additional policy statements to be included in the deployment's KMS key's policy."
}

variable "post_install_script" {
  default     = null
  type        = string
  description = "The path to a custom script to be executed during initial EC2 instance startup."
}

locals {
  validate_influx_db_hostname_and_password = var.is_influx_db_in_secondary_region ? (var.influx_db_hostname != null && var.influx_db_password_arn != null) : (var.influx_db_hostname == null && var.influx_db_password_arn == null && contains(["us-east-1", 
                                                                    "us-east-2",
                                                                    "us-west-2",
                                                                    "ap-south-1",
                                                                    "ap-southeast-1",
                                                                    "ap-southeast-2",
                                                                    "ap-southeast-3",
                                                                    "ap-northeast-1",
                                                                    "ca-central-1",
                                                                    "eu-central-1",
                                                                    "eu-west-1",
                                                                    "eu-west-2",
                                                                    "eu-west-3",
                                                                    "eu-north-1",
                                                                    "eu-south-1",
                                                                    "eu-south-2",
                                                                    "me-central-1"
                                                                  ], data.aws_region.current.name))
  validate_influx_db_hostname_and_password_err_msg = "If you are deploying Etleap in a region that doesn't yet support Amazon Timestream for InfluxDB, then follow the instructions in the README for deploying InfluxDB in a secondary region, set `is_influx_db_in_secondary_region` to `true`, and specify `influx_db_hostname` and `influx_db_password_arn`. If `is_influx_db_in_secondary_region` is set to `false` (default), then neither `influx_db_hostname` or `influx_db_password_arn` should be set."
}

resource "null_resource" "are_influx_db_hostname_and_password_valid" {
  count = local.validate_influx_db_hostname_and_password ? 0 : local.validate_influx_db_hostname_and_password_err_msg
}

# here we are validating the VPC config is valid, and that we have 6 subnets if the user is specifying a VPC ID.
locals {
  validate_vpc_cnd = var.vpc_id == null ? true : (var.public_subnets == null ? false : length(var.public_subnets) == 3) && (var.private_subnets == null ? false : length(var.private_subnets) == 3)
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
data "aws_ec2_instance_type" "dms_instance_type" {
  // DMS instance types are prefixed with "dms.", which isn't supported by "aws_ec2_instance_type" data source
  instance_type = replace(var.dms_instance_type, "dms.", "")
}