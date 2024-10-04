Contains templates for Etleap VPC deployments.

# Creating a new deployment

Below is the minimal module instantiation to run Etleap inside your own VPC.
This will create a new VPC, and deploy Etleap and its associated resources inside. 

Note: This deployment requires Amazon Timestream for InfluxDB to be available in the region Etleap is deployed to, which are currently the following regions: `us-east-1`, `us-east-2`, `us-west-2`, `ap-south-1`, `ap-southeast-1`, `ap-southeast-2`, `ap-northeast-1`, `eu-central-1`, `eu-west-1`, and `eu-north-1`. If you are deploying Etleap in a region that's not in this list, you will need to create a secondary VPC in one of these regions and peer the primary VPC to it. To do this, please follow the instructions for [Deploying Etleap in a region where Amazon Timestream for InfluxDB is not available](#deploying-etleap-in-a-region-where-amazon-timestream-for-influxdb-is-not-available).

## New VPC deployment

```
module "etleap" {
  source  = "etleap/etleap-vpc/aws"
  version = "1.10.1"

  deployment_id    = "deployment" # This will be provided by Etleap
  vpc_cidr_block_1 = 172
  vpc_cidr_block_2 = 22
  vpc_cidr_block_3 = 3
  key_name         = aws_key_pair.ssh.key_name
  first_name       = "John"
  last_name        = "Smith"
  email            = "john.smith@example.com"
}

output "app-hostname" {
  value = module.etleap.app_public_address
}

output "setup-password" {
  sensitive = true
  value     = module.etleap.setup_password
}
```

## Existing VPC deployment

To deploy Etleap in an existing VPC, replace the `vpc_cidr_block_*` variables with:

```
vpc_id           = "vpc-id"
public_subnets   = ["subnet-public-1-id", "subnet-public-2-id", "subnet-public-3-id"]
private_subnets  = ["subnet-private-1-id", "subnet-private-2-id", "subnet-private-3-id"]
```

## Inputs

The following options are available when deploying Etleap.

Note: Either `vpc_cidr_block_1`, `vpc_cidr_block_2`, `vpc_cidr_block_3` or `vpc_id`, `public_subnets`, `private_subnets` are required to be specified. 

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `deployment_id` | The Deployment ID for this deployment. If you don't have one, please contact Etleap Support. | `string` | n/a | yes |
| `vpc_cidr_block_1` | The first octet of the CIDR block of the desired VPC's address space. | `int` | n/a | no |
| `vpc_cidr_block_2` | The second octet of the CIDR block of the desired VPC's address space. | `int` | n/a | no |
| `vpc_cidr_block_3` | The third octet of the CIDR block of the desired VPC's address space. | `int` | n/a | no |
| `key_name` | The AWS Key Pair to use for SSH access into the EC2 instances. | `string` | n/a | yes |
| `first_name` | The first name to use when creating the first Etleap user account. | `string` | n/a | yes |
| `last_name` | The last name to use when creating the first Etleap user account. | `string` | n/a | yes |
| `email` | The email to use when creating the first Etleap user account. | `string` | n/a | yes |
| `vcp_id` | Existing VPC to deploy Etleap in. VPC's that have a CIDR range that overlaps `192.168.0.1/24` are not currently supported. | `string` | n/a | no |
| `public_subnets` | Existing public subnets to deploy Etleap in. | `list(string)` | n/a | no |
| `private_subnets` | Existing private subnets to deploy Etleap in. | `list(string)` | n/a | no |
| `extra_security_groups` | Grant access to the DB, EC2 instance, and EMR cluster to the specified Security Groups | `list(string)` | `[]` | no |
| `app_hostname`| The hostname where Etleap will be accessible from. If left empty, the default Load Balancer DNS name will be used. | `string` | `null` | no |
| `app_available`| Only use this if instructed by ETLeap support. Enable or disable to start or destroy the app instance. | `boolean` | `true` | yes |
| `ha_mode`| Enables High Availability mode. This will run two redundant Etleap instances in 2 availability zones, and set the RDS instace to "multi-az" mode. | `boolean` | `false` | no | 
| `app_private_ip` | The Private IP for the main application instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP. | `string` | `null` | no |
| `secondary_private_ip`| The Private IP for the seconday application instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP. | `string` | `null` | no |
| `nat_private_ip` | The Private IP for the NAT instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP. | `string` | `null` | no |
| `non_critical_cloudwatch_alarm_sns_topics` | A list of SNS topics to notify when non critical alarms are triggered. For the list of non-critical alarms, see _CloudWatch Alarms_ under _Monitoring and operation_. | `list(string)` | `[]` | no |
| `critical_cloudwatch_alarm_sns_topics` | A list of SNS topics to notify when critical alarms are triggered. For the list of critical alarms, see _CloudWatch Alarms_ under _Monitoring and operation_. | `list(string)` | `[]` | no |
| `app_instance_type` | The instance type for the main app node(s). Defaults to `t3.xlarge`. We do not recommend using a smaller instance type. | `string` | `t3.xlarge` | no |
| `nat_instance_type` | The instance type for the NAT instance. Defaults to `m5n.large`. | `string` | `m5n.large` | no |
| `rds_instance_type` | The instance type for the RDS instance. Defaults to `db.m5.large`. We do not recommend using a smaller instance type. | `string` | `db.m5.large` | no |
| `dms_instance_type` | The instance type for the DMS instance. Defaults to `dms.t2.small`. Not used if `disable_cdc_support` is set to `true`. | `boolean` | `true` | no |
| `disable_cdc_support` | Set to true if this deployment will not use CDC pipelines. This will cause the DMS Replication Instance and associated resources not to be created. Defaults to `false`. | `boolean` | `false` | no |
| `dms_roles_to_be_created` | Set to `true` if this template should create the roles required by DMS, `dms-vpc-role` and `dms-cloudwatch-logs-role`. Set to `false` if are already using DMS in the account where you deploy Etleap. | `boolean` | `true` | no |
| `unique_resource_names` | If set to 'true', a suffix is appended to resource names to make them unique per deployment. Recommend leaving this as 'true' except in the case of migrations from earlier versions. | `boolean` | `true` | no |
| `s3_input_buckets` | The names of the S3 buckets which will be used with "S3 Input" connections. The module will create an IAM role to be specified with the "S3 Input" connections, together with a bucket policy that needs to be applied to the bucket. | `list(string)` | `[]` | no
| `s3_data_lake_account_ids` | The 12-digit IDs of the AWS accounts containing the roles specified with "S3 Data Lake" connections. IAM roles in these accounts are given read access to the intermediate data S3 bucket. | `list(string)` | `[]` | no |
| `github_username` | Github username to use when accessing custom transforms | `string` | `null` | no | 
| `github_access_token_arn` | ARN of the secret containing the GitHub access token | `string` | `null` | no |
| `connection_secrets` | A map between environment variables and Secrets Manager Secret ARN for secrets to be injected into the application. This is only used for enabling certain integration. | `map(string, string)` | `{}` | no |
| `resource_tags` | Resource tags to be applied to all resources create by this template. | `map(string, string)` | `{}` | no |
| `app_access_cidr_blocks` | CIDR ranges that have access to the application (port 443). Defaults to allowing all IP addresses. | `list(string)` | `["0.0.0.0"]` | no |
| `ssh_access_cidr_blocks` | CIDR ranges that have SSH access to the application instance(s) (port 22).  Defaults to allowing all IP addresses. | `list(string)` | `["0.0.0.0"]` | no |
| `outbound_access_destinations` | CIDR ranges, ports and protocols to allow outbound access to for pipeline sources and destinations. Defaults to allowing all outbound traffic. Note that regardless of this value, outbound traffic to ports 80 and 443 is always allowed. | `list(map(string, any))` | all outbound traffic | no |
| `roles_allowed_to_be_assumed` |A list of external roles that can be assumed by the app. When not specified, it defaults to all roles (*) | `list(string)` | `[]` | no |
| `enable_public_access` |Enable public access to the Etleap deployment. This will create an _Internet facing_ ALB. Defaults to `true`. | `boolean` | `true` | no |
| `acm_certificate_arn` | "ARN Certificate to use for SSL connections to the Etleap UI. If the certificate is specified, it must use either RSA_1024 or RSA_2048. See https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html for more details. If no certificate is specified, the deployment will use a default one bundled with the template. | `string` | `null` | no |
| `rds_backup_retention_period` | The number of days to retain the automated database snapshots. Defaults to 7 days. | `int` | `7` | no |
| `rds_allow_major_version_upgrade` | Only use this if instructed by ETLeap support. Indicates that major version upgrades are allowed. | `boolean` | `false` | no |
| `rds_apply_immediately` | If any RDS modifications are required they will be applied immediately instead of during the next maintenance window. It is recommended to set this back to `false` once the change has been applied. | `boolean` | `false` | no |
| `emr_core_node_count` | The number of EMR core nodes in the EMR cluster. Defaults to 1. | `int` | `1` | no |
| `allow_iam_devops_role` | Enable access to the deployment for Etleap by creating an IAM role that Etleap's ops team can assume. Defaults to false. | `boolean` | `false` | no |
| `allow_iam_support_role` | Enable access to the support role for Etleap by creating an IAM role that Etleap's support team can assume. Defaults to true. | `boolean` | `true` | no |
| `enable_streaming_ingestion` | Enable support and required infrastructure for streaming ingestion sources. Currently only supported in `us-east-1` and `eu-west-3` regions. | `boolean` | `false` | no |
| `streaming_endpoint_hostname` | The hostname the streaming ingestion webhook will be accessible from. Only has an effect if `enable_streaming_ingestion` is set to `true`. If left empty, the default Load Balancer DNS name will be used. | `string` | `null` | no |
| `streaming_endpoint_acm_certificate_arn` | ARN Certificate to use for SSL connections to the streaming ingestion webhook. If the certificate is specified, it must use either RSA_1024 or RSA_2048. See https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html for more details. If no certificate is specified, the deployment will use a default one bundled with the template. | `string` | `null` | no |
| `streaming_endpoint_access_cidr_blocks` | CIDR ranges that have access to the streaming ingestion webhook (both HTTP and HTTPS). Defaults to allowing all IP addresses. | `list(string)` | ``["0.0.0.0/0"]`` | no |


## Outputs

| Name | Description |
|------|-------------|
| `app_public_address` | The DNS address of the ALB that serves the Etleap Web UI. |
| `streaming_endpoint_public_address` | The DNS address of the ALB that serves the streaming ingestion webhook. |
| `s3_input_role_arn` | Role to use when setting up S3 Input connections with a bucket from a different AWS account. |
| `s3_input_bucket_policy` | Policies that need to applied to the S3 buckets specified by 's3_input_buckets' so Etleap's role can read from them. |
| `setup_password` | The password to log into Etleap for the first time. You'll be prompted to change it after on first login. |
| `vpc_id` | The VPC ID where Etleap is deployed |
| `public_subnet_a` | The first public subnet for Etleap's VPC | 
| `public_subnet_b` | The second public subnet for Etleap's VPC |
| `private_subnet_a` | The first private subnet for Etleap's VPC |
| `private_subnet_b` | The second private subnet for Etleap's VPC |
| `public_route_table_id` | The public subnets' route table, if managed by the module |
| `private_route_table_id` | The public subnets' route table, if managed by the module |
| `private_route_table_id` | The public subnets' route table, if managed by the module |
| `emr_cluster_id` | The ID of Etleap's EMR cluster | 
| `intermediate_bucket_id` | The ID of Etleap's intermediate bucket |
| `deployment_id` | The Deployment ID |
| `main_app_instance_id` | The instance ID of the main application instance. |
| `secondary_app_instance_id` | The instance ID of the secondary application instance. |
| `kms_policy` | Statement to add to the KMS key if using a Customer-Manager SSE KMS key for encrypting S3 data. |
| `nat_ami` | Status of the NAT AMI (if created) |

# Connecting to the Etleap deployment

After Terraform has finished applying the changes, it may take up to 30 minutes for the application to be available.
This time is required to configure the EC2 instances, database and EMR cluster.

Go to the URL in the `app-hostname`, and use the email provided in the template to login.
A temporary password was created as part of the deployment, and it's value is the output of `terraform output setup-password`.

Once logged in you'll be prompted to create a new password.

# Monitoring and operation

## CloudWatch Alarms

This module defines a number of CloudWatch alarms that can be used to alert your infrastructure operations team when the deployment is in a bad state. 
The table below describes the alarms that are defined, together with the action recommended to remedy them. 
Critical alarms are for conditions that cause pipelines to stop.

| Alarm                                  | Critical | Cause                                                                                    | Resolution                                                                                                                                                                                            |
|----------------------------------------|----------|------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| EMR Cluster Running                    | Yes      | EMR cluster is not running                                                               | See the section on *Reprovisioning a new EMR cluster*                                                                                                                                                 |
| 60% Disk EMR HDFS                      | No       | Not enough core nodes for the workload                                                   | Increase the number of core nodes via the Terraform variable `emr_core_node_count`.                                                                                                                   |
| EMR Unhealthy Nodes                    | No       | EMR cluster is in a bad state                                                            | Taint the cluster and see the section on *Reprovisioning a new EMR cluster*                                                                                                                           |
| EMR Missing Blocks                     | No       | Missing HDFS blocks means we lost one or more core nodes                                 | Taint the cluster and the section on *Reprovisioning a new EMR cluster*                                                                                                                               |
| 80% Disk EMR NameNode                  | Yes      | The disk is filling up on the name ndoe                                                  | Taint the cluster and the section on *Reprovisioning a new EMR cluster*                                                                                                                               |
| RDS CPU 90%                            | No       | RDS instance is saturating CPU                                                           | Increase the RDS instance size                                                                                                                                                                        |
| RDS Disk Space                         | Yes      | RDS is running out of disk space                                                         | Increase the `allocated_storage` via Terraform, or via the console                                                                                                                                    |
| RDS Freeable Memory                    | No       | RDS is running out of disk space                                                         | Increase the `allocated_storage` via Terraform, or via the console                                                                                                                                    |
| * Node 80% CPU                         | No       | CPU usage is high on the specified instance                                 | Upgrade the instance type to the next larger size within the same instance family. If you wish to upgrade from `t3.2xlarge`, which is the largest `t3` instance available, please switch to the `c6a` family.      |
| * 90% Disk *                           | Yes      | Disk is getting full for one of the instances                                            | Increase the EBS size of the attached volumes; contact Etleap Support to diagnose to root cause                                                                                                       |
| App is running                         | Yes      | The main web application is down and not accepting requests                              | If in single-availability node, reprovision the instance. If in High-Availablity mode, reprovision both instances, and contact Etleap Support to determine the cause of the outage                    |
| Job is running                         | Yes      | The data processing application is down                                                  | If in single-availability node, reprovision the instance. If in High-Availablity mode, reprovision both instances, and contact Etleap Support to determine the cause of the outage                    |
| DMS Disk Space 30GB Remaining          | Yes      | DMS replication instance is running out of disk space                                    | Contact Support                                                                                                                                                                                       |
| DMS Available Memory <= 10%            | No       | DMS replication instance is running out of memory                                        | Upgrade the instance type to the next larger size within the same instance family                                                                                                                     |
| DMS Freeable Memory <= 10%             | No       | DMS replication instance is running out of memory                                        | Upgrade the instance type to the next larger size within the same instance family                                                                                                                     |
| Elva Healthy Host Count                | Yes      | The number of streaming ingestion nodes is too low.                                      | Contact Support                                                                                                                                                                                       |
| Zookepeer Unhealthy Nodes              | Yes      | Zookeeper cluster has Unhealthy Nodes                                                    | Contact Support                                                                                                                                                                                       |
| * App Kinesis logger agent is running  | Yes      | A Kinesis logger agent is not running                                                    | Contact Support                                                                                                                                                                                       |
| High Job GC Activity                   | Yes      | The data processing application is spending a significant time doing garbage collection. | If the monitored metric has been steadily increasing over time, upgrade the `app_instance_type` to one that has more memory. Contact support if this alarm is caused by a sudden spike in the metric. |

### Reprovisioning a new EMR cluster

If the `EMR Cluster Running`, `EMR Unhealthy Nodes` or `EMR Missing Blocks` alarm has triggered, you'll need to start a new EMR cluster.
Before running terraform, run the following script to send any relevant logs and metrics to Etleap for analysis (if you have the option enabled for you deployment).

```
CLUSTER_ID=$(terraform output -raw emr_cluster_id)
INTERMEDIATE_BUCKET=$(terraform output -raw intermediate_bucket_id)
DEPLOYMENT_ID=$(terraform output -raw deployment_id)
aws s3 cp s3://$INTERMEDIATE_BUCKET/emr-logs/$CLUSTER_ID/ s3://etleap-vpc-emr-logs/$DEPLOYMENT_ID/$CLUSTER_ID/ --acl bucket-owner-full-control --recursive
```

Once this is done, you can run `terrafrom apply` to recreate or replace the cluster, as the need may be.

# Security upgrades

This section provides information on how to run security upgrade for the deployment.

EC2 instances that are part of this deployment are designed to upgrade and apply any updates when they first start up.
We do not support patching existing instances, so the following instruction swill guide you on how to replace the instances while minimizing downtime.

## Upgrading the Application Instances

Expected Downtime:
- API and Web UI:
  - HA Mode: none
  - Regular Mode: 10-15 minutes
- Pipelines: 10-15 minutes 

> **Note**
> if you plan on upgrading the EMR cluster as well, perform that upgrade first, as it will require replacing the application instances as part of the upgrade.

### Step 1: Regular and HA Mode

1. Run terraform to replace the main application instance: `terraform apply -replace 'module.etleap.module.main_app[0].aws_instance.app'`;

2. Once the apply finishes, check if the application is online:

    a. In the AWS EC2 Console, go to "Target Groups" 

    b. Select the "Etleap*" Target group. To get the exact name run: `terraform state show module.etleap.aws_lb_target_group.app`.

    c. Under the "Targets" tab, check that all instances are "Healthy". 

3. Once all instances are healthy, you can continue with the next step.

### Step 2: HA Mode only

1. Run terraform to replace the secondary instance: `terraform apply -replace 'module.etleap.module.secondary_app[0].aws_instance.app'`;

## Upgrading the Zookeeper Cluster

Downtime: none

> **Warning**
> To ensure 0 downtime, the upgrade must be performed one instance at a time.
> Make sure that all 3 Zookeeper nodes are healthy before moving to the next one.

1. Check the maximum of the `Etleap/Zookeeper Ruok` metric is 1 for all 3 instances. If this is not the case, contact support@etleap.com before proceeding. 

2. Taint the zookeeper instance: `terraform apply -replace 'module.etleap.aws_instance.zookeeper["1"]'`

3. Run `terraform apply`;

4. Wait for at least 10 minutes, and monitor until the `Etleap/Zookeeper Ruok` metric is 1 for the instance that was replaced. If the metric doesn't recover after 20 minutes, contact support@etleap.com before proceeding further. 

5. Repeat steps 1-4 for the remaining 2 instances: `'module.etleap.aws_instance.zookeeper["2"]'` and `'module.etleap.aws_instance.zookeeper["3"]'`.

## Upgrading the EMR Cluster

Downtime:
- API and Web UI: none
- Pipelines: 10-15 minutes

1. Remove the old cluster from the state: `terraform state rm module.etleap.aws_emr_cluster.emr` and `terraform state rm module.etleap.aws_emr_instance_group.task_spot`;

2. Run `terraform apply -target module.etleap.aws_emr_cluster.emr -target module.etleap.aws_emr_instance_group.task_spot` to create a new cluster;

3. Once the the apply completes, replace the main application instance: `terraform apply -target module.etleap.module.main_app[0].aws_instance.app -target module.etleap.aws_lb_target_group_attachment.main_app[0]`;

4. Monitor that the instance comes online:

    a. In the AWS EC2 Console, go to "Target Groups" 

    b. Select the "Etleap*" Target group. To get the exact name run: `terraform state show module.etleap.aws_lb_target_group.app`.

    c. Under the "Targets" tab, check that all instances are "Health". 

5. Once the main instance is online, apply the remaining changes with `terraform apply`. If HA Mode is enabled, this will also replace the secondary application instace. 
6. Manually terminate the old cluster from the AWS Console or the CLI.

## Deploying Etleap in a region where Amazon Timestream for InfluxDB is not available 

In order to run Etleap in a region that doesn't support Amazon Timestream you will need to provide an InfluxDB endpoint and password (variables `influx_db_hostname` and `influx_db_password_arn`). Follow the steps below to instantiate the Amazon Timestream for InfluxDB instance in one of the supported regions, and creating a VPC peering connection from the Etleap module's VPC to it.

1. Create a new Terraform (.tf) file in the same directory as the file instantiating the `etleap/etleap-vpc/aws` module, with the following code.

```
provider "aws" {
  alias   = "secondary"
  region  = <region>
  version = "~> 5.61"
}

data "aws_region" "main" {
  provider = aws
}

data "aws_region" "secondary" {
  provider = aws.secondary
}

data "aws_vpc" "main" {
  id = module.<module-name>.vpc_id
}

locals {
  deployment_id                             = <deployment_id>
  main_vpc_private_route_table_id           = module.vpc.private_route_table_id

  # The CIDR blocks can be adjusted to fit the requirements
  secondary_vpc_cidr_block                  = "172.0.0.0/27"
  secondary_vpc_private_subnet_a_cidr_block = "172.0.0.0/28"
  secondary_vpc_private_subnet_b_cidr_block = "172.0.0.16/28"
  secondary_region                          = data.aws_region.secondary.name

  main_vpc_id                               = data.aws_vpc.main.id
  main_vpc_region                           = data.aws_region.main.name
  main_vpc_cidr_block                       = data.aws_vpc.main.cidr_block

  default_tags = merge({
    Deployment = local.deployment_id
  })
}

# Password for InfluxDB
resource "random_password" "secret_value" {
  length  = 20
  special = false
  lifecycle {
    ignore_changes = [length, lower, min_lower, min_numeric, min_special, min_upper, numeric, special, upper, keepers]
  }
}

resource "aws_secretsmanager_secret" "influxdb_password" {
  name          = "EtleapInfluxDbPassword${local.deployment_id}"
  tags          = local.default_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "influxdb_password" {
  secret_id     = aws_secretsmanager_secret.influxdb_password.id
  secret_string = random_password.secret_value.result
}

# InfluxDB
resource "aws_timestreaminfluxdb_db_instance" "influx_db" {
  name                   = "etleap-ingest-metrics-${local.deployment_id}"
  username               = "root"
  password               = aws_secretsmanager_secret_version.influxdb_password.secret_string
  db_instance_type       = "db.influx.medium"
  vpc_subnet_ids         = [aws_subnet.subnet_a_private_influx.id, aws_subnet.subnet_b_private_influx.id]
  vpc_security_group_ids = [aws_security_group.influxdb.id]
  allocated_storage      = 100
  organization           = "etleap"
  bucket                 = "raw_bucket"
  publicly_accessible    = false
  deployment_type        = var.ha_mode ? "WITH_MULTIAZ_STANDBY" : "SINGLE_AZ"
  tags                   = local.default_tags
  provider               = aws.secondary
}

# All VPC resources
resource "aws_vpc" "etleap_influx" {
  tags                 = merge({Name = "Etleap Influx VPC ${local.deployment_id}"}, local.default_tags)
  cidr_block           = local.secondary_vpc_cidr_block
  enable_dns_hostnames = true
  provider             = aws.secondary
}

resource "aws_subnet" "subnet_a_private_influx" {
  vpc_id            = aws_vpc.etleap_influx.id
  cidr_block        = local.secondary_vpc_private_subnet_a_cidr_block

  availability_zone = "${local.secondary_region}a"
  tags              = merge({Name = "Etleap Secondary VPC Subnet A"}, local.default_tags)
  provider          = aws.secondary
}

resource "aws_subnet" "subnet_b_private_influx" {
  vpc_id            = aws_vpc.etleap_influx.id
  cidr_block        = local.secondary_vpc_private_subnet_b_cidr_block

  availability_zone = "${local.secondary_region}b"
  tags              = merge({Name = "Etleap Secondary VPC Subnet B"}, local.default_tags)
  provider          = aws.secondary
}

resource "aws_security_group" "influxdb" {
  tags        = merge({Name = "Etleap Influx Security Group"}, local.default_tags)
  name        = "Etleap InfluxDB Supplemental"
  description = "Etleap InfluxDB Supplemental"
  vpc_id      = aws_vpc.etleap_influx.id
  provider    = aws.secondary
}

resource "aws_security_group_rule" "app-to-influxdb" {
  type               = "ingress"
  from_port          = 8086
  to_port            = 8086
  protocol           = "tcp"
  security_group_id  = aws_security_group.influxdb.id
  provider           = aws.secondary
  cidr_blocks        = [local.main_vpc_cidr_block]
}

# VPC peering resources
resource "aws_vpc_peering_connection" "secondary_to_main" {
  peer_vpc_id   = local.main_vpc_id
  vpc_id        = aws_vpc.etleap_influx.id
  peer_region   = local.main_vpc_region
  provider      = aws.secondary
  tags          = merge({Name = "Etleap Influx Peering Connection"}, local.default_tags)
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  tags                      = merge({Name = "Etleap Influx Peer Connection Accceptor ${local.deployment_id}"}, local.default_tags)
  vpc_peering_connection_id = aws_vpc_peering_connection.secondary_to_main.id
  auto_accept               = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route_table" "private_influx" {
  tags     = merge({Name = "Etleap Private Influx Supplemental ${local.deployment_id}"}, local.default_tags)
  vpc_id   = aws_vpc.etleap_influx.id
  provider = aws.secondary
}

resource "aws_route" "private_route_to_main" {
  route_table_id            = aws_route_table.private_influx.id
  destination_cidr_block    = local.main_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.secondary_to_main.id
  provider                  = aws.secondary
}

resource "aws_route_table_association" "a_private_influx" {
  subnet_id      = aws_subnet.subnet_a_private_influx.id
  route_table_id = aws_route_table.private_influx.id
  provider       = aws.secondary
}

resource "aws_route_table_association" "b_private_influx" {
  subnet_id      = aws_subnet.subnet_b_private_influx.id
  route_table_id = aws_route_table.private_influx.id
  provider       = aws.secondary
}

# Main VPC route
resource "aws_route" "main_to_influx_route" {
  route_table_id            = local.main_vpc_private_route_table_id
  destination_cidr_block    = local.secondary_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.secondary_to_main.id
}

```

2. Make the following changes in your new file: 

  - Replace `<region>` in the secondary AWS provider with one of the regions that support Amazon Timestream for InfluxDB: `us-east-1`, `us-east-2`, `us-west-2`, `ap-south-1`, `ap-southeast-1`, `ap-southeast-2`, `ap-northeast-1`, `eu-central-1`, `eu-west-1`, or `eu-north-1`.
  ```
  provider "aws" {
    alias   = "secondary"
    region  = <region>
    version = "~> 5.61"
  }
  ```

  - Replace `<module-name>` with the module name you chose for your [Etleap VPC deployment](#new-vpc-deployment).
  ```
  data "aws_vpc" "main" {
    id = module.<module-name>.vpc_id
  }
  ```

  - In the `locals` block, replace `<deployment-id>` with the value that you used in your [Etleap VPC module](#new-vpc-deployment), and `<module-name>` with the same one used above.ed in [New VPC deployment](#new-vpc-deployment). Additionally, replace the module name to the same one used above.
  ```
  locals {
    deployment_id                   = <deployment-id>
    main_vpc_private_route_table_id = module.<module-name>.private_route_table_id

    # ...
  }
  ```

  - [Optional] In the case you have a CIDR range conflict in your secondary region, adjust the `secondary_vpc_cidr_block`, `secondary_vpc_private_subnet_a_cidr_block`, and `secondary_vpc_private_subnet_b_cidr_block` to a range that does not conflict with other CIDR ranges in use. Please ensure that the range selected for `secondary_vpc_cidr_block` uses subnet mask "/27" and the ranges selected for `secondary_vpc_private_subnet_a_cidr_block` and `secondary_vpc_private_subnet_b_cidr_block` use subnet mask "/28".
  ```
  locals {
    # ...

    secondary_vpc_cidr_block                  = "172.0.0.0/27"
    secondary_vpc_private_subnet_a_cidr_block = "172.0.0.0/28"
    secondary_vpc_private_subnet_b_cidr_block = "172.0.0.16/28"
    
    # ...
  }
  ```

3. Additionally, pass these parameters to the module.

In the module definition created in [New VPC deployment](#new-vpc-deployment), add the following lines.
```
  influx_db_hostname                = aws_timestreaminfluxdb_db_instance.influx_db.endpoint
  influx_db_password_arn            = aws_secretsmanager_secret.influxdb_password.arn
  is_influx_db_in_secondary_region  = true
```

4. To initialize Etleap deployment, run the following commands to recreate terraform resources:

```
terraform init
terraform apply -target aws_timestreaminfluxdb_db_instance.influx_db
terraform apply
```

## Restrict outbound access

By default, we allow all outbound access, on all ports to all IP addresses. 
The module allows you to restrict outbound access for the deployment to the specified list of CIDR blocks, or specific security groups. 
For example, to restrict outbound access to just Postgres DBs running in the 172.18.0.0/16 subnet, use the following definition:

```
outbound_access_destinations = [{
  cidr_block = "172.18.0.0/16",
  from_port  = 5432,
  to_port    = 5432,
  protocol   = "tcp"
}]
```

Alternatively, you can restrict based on a security group ID instead of a CIDR block when the security group is in the same VPC as Etleap is deployed in:

```
outbound_access_destinations = [{
  target_security_group_id = "sg-xxxxx",
  from_port                = 5432,
  to_port                  = 5432,
  protocol                 = "tcp"
}]
```

> **Warning**
> The deployment will always have outbound access to ports 80 and 443, for license checking, instance lifecycle purposes (e.g. applying security upgrades), and access to the AWS APIs.