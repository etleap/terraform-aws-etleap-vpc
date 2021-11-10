Contains templates for Etleap VPC deployments.

# Creating a new deployment

Below is the minimal module instantiation to run Etleap inside your own VPC.
This will create a new VPC, and deploy Etleap and its associated resources inside.

## New VPC deployment

```
module "etleap" {
  source  = "etleap/etleap-vpc/aws"
  version = "1.0.6"

  region           = "us-east-1"
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
  value = module.vpc.app_public_address
}

output "setup-password" {
  sensitive = true
  value     = module.vpc.setup_password
}
```

## Existing VPC deployment

To deploy Etleap in an existing VPC, replace the `vpc_cird_block_*` variables with:

```
vpc_id           = "vpc-id"
public_subnets   = ["subnet-public-1-id", "subnet-public-2-id"]
private_subnets  = ["subnet-private-1-id", "subnet-private-2-id"]
```

## Inputs

The following options are available when deploying Etleap.

Note: Either `vpc_cidr_block_1`, `vpc_cidr_block_2`, `vpc_cidr_block_3` or `vpc_id`, `public_subnets`, `private_subnets` are required to be specified. 

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `region` | The region Etleap is deployed in. | `string` | n/a | yes |
| `deployment_id` | The Deployment ID for this deployment. If you don't have one, please contact Etleap Support. | `string` | n/a | yes |
| `vpc_cidr_block_1` | The frist octet of the CIDR block of the desired VPC's address space. | `int` | n/a | no |
| `vpc_cidr_block_2` | The second octet of the CIDR block of the desired VPC's address space. | `int` | n/a | no |
| `vpc_cidr_block_3` | The third octet of the CIDR block of the desired VPC's address space. | `int` | n/a | no |
| `key_name` | The AWS Key Pair to use for SSH access into the EC2 instances. | `string` | n/a | yes |
| `first_name` | The first name to use when creating the first Etleap user account. | `string` | n/a | yes |
| `last_name` | The last name to use when creating the first Etleap user account. | `string` | n/a | yes |
| `email` | The email to use when creating the first Etleap user account. | `string` | n/a | yes |
| `vcp_id` | Existing VPC to deploy Etleap in. | `string` | n/a | no |
| `public_subnets` | Existing public subnets to deploy Etleap in. | `list(string)` | n/a | no |
| `private_subnets` | Existing private subnets to deploy Etleap in. | `list(string)` | n/a | no |
| `extra_security_groups` | Grant access to the DB, EC2 instance, and EMR cluster to the specified Security Groups | `list(string)` | `[]` | no |
| `app_hostname`| The hostname where Etleap will be accessible from. If left empty, the default Load Balancer DNS name will be used. | `string` | `null` | no |
| `ha_mode`| Enables High Availability mode. This will run two redundant Etleap instances in 2 availability zones, and set the RDS instace to "multi-az" mode. | `boolean` | `false` | no | 
| `app_private_ip` | The Private IP for the main application instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP. | `string` | `null` | no |
| `secondary_private_ip`| The Private IP for the seconday application instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP. | `string` | `null` | no |
| `nat_private_ip` | The Private IP for the NAT instance. Use if you want to set it to a predetermined value. By default, the application will be assigned a random IP. | `string` | `null` | no |
| `non_critical_cloudwatch_alarm_sns_topics` | A list of SNS topics to notify when non critical alarms are triggered. For the list of non-critical alarms, see _CloudWatch Alarms_ under _Monitoring and operation_. | `list(string)` | `[]` | no |
| `critical_cloudwatch_alarm_sns_topics` | A list of SNS topics to notify when critical alarms are triggered. For the list of critical alarms, see _CloudWatch Alarms_ under _Monitoring and operation_. | `list(string)` | `[]` | no |
| `app_instance_type` | The instance type for the main app node(s). Defaults to t3.xlarge. We do not recommend using a smaller instance type. | `string` | `t3.xlarge` | no |
| `nat_instance_type` | The instance type for the NAT instance. Defaults to `m5n.large`. | `string` | `m5n.large` | no |
| `dms_instance_type` | The instance type for the DMS instance. Defaults to `dms.t2.small`. Not used if `disable_cdc_support` is set to `true`. | `boolean` | `true` | no |
| `disable_cdc_support` | Set to true if this deployment will not use CDC pipelines. This will cause the DMS Replication Instance and associated resources not to be created. Defaults to `false`. | `boolean` | `false` | no |
| `dms_roles_to_be_created` | Set to `true` if this template should create the roles required by DMS, `dms-vpc-role` and `dms-cloudwatch-logs-role`. Set to `false` if are already using DMS in the account where you deploy Etleap. | `boolean` | `true` | no |
| `unique_resource_names` | If set to 'true', a suffix is appended to resource names to make them unique per deployment. Recommend leaving this as 'true' except in the case of migrations from earlier versions. | `boolean` | `true` | no |
| `s3_input_buckets` | The names of the S3 buckets which will be used with "S3 Input" connections. The module will create an IAM role to be specified with the "S3 Input" connections, together with a bucket policy that needs to be applied to the bucket. | `list(string)` | `[]` | no
| `s3_data_lake_account_ids` | The 12-digit IDs of the AWS accounts containing the roles specified with "S3 Data Lake" connections. IAM roles in these accounts are given read access to the intermediate data S3 bucket. | `list(string)` | `[]` | no |
| `github_username` | Github username to use when accessing custom transforms | `string` | `null` | no | 
| `github_access_token` | ARN of the secret containing the GitHub access token | `string` | `null` | no |
| `connection_secrets` | A map between environment variables and Secrets Manager Secret ARN for secrets to be injected into the application. This is only used for enabling certain integration. | `map(string, string)` | `{}` | no |
| `resource_tags` | Resource tags to be applied to all resources create by this template. | `map(string, string)` | `{}` | no |
| `app_access_cidr_blocks` | CIDR ranges that have access to the application (port 443). Defaults to allowing all IP addresses. | `list(string)` | `["0.0.0.0"]` | no |
| `ssh_access_cidr_blocks` | CIDR ranges that have SSH access to the application instance(s) (port 22).  Defaults to allowing all IP addresses. | `list(string)` | `["0.0.0.0"]` | no |
| `roles_allowed_to_be_assumed` |A list of external roles that can be assumed by the app. When not specified, it defaults to all roles (*) | `list(string)` | `[]` | no |
| `enable_public_access` |Enable public access to the Etleap deployment. This will create an _Internet facing_ ALB. Defaults to `true`. | `boolean` | `true` | no |
| `acm_certificate_arn` | "ARN Certificate to use for SSL. If the certificate is specified, it must use either RSA_1024 or RSA_2048. See https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html for more details. If no certificate is specified, the deployment will use a default one bundled with the template. | `string` | `null` | no |
| `rds_backup_retention_period` | The number of days to retain the automated database snapshots. Defaults to 7 days. | `int` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| `app_public_address` | The DNS address of the ALB |
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

| Alarm | Critical | Cause | Resolution |
|---|---|---|---|
| EMR Cluster Running | Yes | EMR cluster is not running | See the section on *Reprovisioning a new EMR cluster* |
| 60% Disk EMR HDFS | No | Not enough core nodes for the workload | Increase the number of core nodes via the console or Terraform |
| EMR Unhealthy Nodes | No | EMR cluster is in a bad state | Taint the cluster and see the section on *Reprovisioning a new EMR cluster*  |
| EMR Missing Blocks | No | Missing HDFS blocks means we lost one or more core nodes | Taint the cluster and the section on *Reprovisioning a new EMR cluster* |
| RDS CPU 90% | No | RDS instance is saturating CPU | Increase the RDS instance size |
| RDS Disk Space | Yes | RDS is running out of disk space | Increase the `allocated_storage` via Terraform, or via the console |
| RDS Freeable Memory | No | RDS is running out of disk space | Increase the `allocated_storage` via Terraform, or via the console |
| * Node 80% CPU | No | CPU usage is consistently high on the specified instance | Upgrade the instance type to a larger one, or one of a newer generation, if available |
| * 90% Disk * | Yes | Disk is getting full for one of the instances | Increase the EBS size of the attached volumes; contact Etleap Support to diagnose to root cause |
| App is running | Yes | The main web application is down and not accepting requests | If in single-availability node, reprovision the instance. If in High-Availablity mode, reprovision both instances, and contact Etleap Support to determine the cause of the outage |
| Job is running | Yes | The data processing application is down | If in single-availability node, reprovision the instance. If in High-Availablity mode, reprovision both instances, and contact Etleap Support to determine the cause of the outage |

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
