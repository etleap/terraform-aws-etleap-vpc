# Release 1.14.1

Adds the `emr_kms_encryption_key` variable to allow specifying an existing KMS key for EMR local disk encryption, instead of creating a new one.

Also adds an internal variable to disable the creation of Cognito identity pools.

Fixes an issue where updating the `s3_kms_encryption_key` would cause `terraform apply` to fail because the module would attempt to replace the EMR Security Configuration without replacing the EMR cluster.

This upgrade requires replacement of the EMR cluster, which will cause 10-15 minutes of downtime to pipelines. The API and Web UI will be unaffected.

# Release 1.14.0

Removes GitHub webhook infrastructure previously used for dbt CI that was introduced in version 1.11.4, as webhooks are now received and processed centrally. The API Gateway and associated resources have been removed.

The `github_webhooks_domain_name_and_certificate` variable has been removed.

## Upgrade instructions

If you have specified the `github_webhooks_domain_name_and_certificate` variable, please remove it from your module definition.

# Release 1.13.14

Adds deployment ID as a dimension to the Zookeeper CloudWatch metrics. This scopes the metrics to a specific Etleap deployment and fixes an issue where the “Zookeeper cluster has Unhealthy Nodes” alarm would only fire when nodes across all deployments in the AWS account were unhealthy.

## Upgrade instructions

This upgrade will replace the Zookeeper instances, causing 10-15 minutes of downtime.
If you would like to upgrade without downtime, please follow the instructions for [upgrading the Zookeeper Cluster](./README.md#upgrading-the-zookeeper-cluster).

# Release 1.13.13

Adds automatic version upgrades for AWS DMS, eliminating the need for manual upgrades when new versions become the default.

# Release 1.13.12

Resolves a rare issue where EMR disks would fill up due to memory heap dumps, by removing excess memory heap dumps regularly.

This upgrade requires replacement of the EMR cluster, which will cause 10-15 minutes of downtime to pipelines. The API and Web UI will be unaffected.

# Release 1.13.11

Upgrades dbt from version 1.9, which has reached end of life, to version 1.10.

This upgrade requires replacement of the EMR cluster, which will cause 10-15 minutes of downtime to pipelines. The API and Web UI will be unaffected.

## Upgrade instructions

1. Update the module version to `1.13.11` and run `terraform apply`.
2. [Replace the EMR Cluster](/README.md#upgrading-the-emr-cluster).

# Release 1.13.10

Fixes an issue introduced in version 1.13.0 where certain logs were not forwarded from the App instances, and resolves a long-standing issue with log forwarding from the Zookeeper instances.

## Upgrade instructions

This upgrade will replace the App and Zookeeper instances, causing 10-15 minutes of downtime.
If you would like to upgrade without downtime, please follow the instructions for [upgrading the App](./README.md#upgrading-the-application-instances) and [Zookeeper](./README.md#upgrading-the-zookeeper-cluster) instances.

# Release 1.13.9

Upgrades App and Etleap Zookeeper EC2 instances to use and require IMDSv2 instead of IMDSv1.

## Upgrade instructions

This upgrade will replace the App and Zookeeper instances, causing 10-15 minutes of downtime.
If you would like to upgrade without downtime, please follow the instructions for [upgrading the App](./README.md#upgrading-the-application-instances) and [Zookeeper](./README.md#upgrading-the-zookeeper-cluster) instances.

# Release 1.13.8

Fixed an issue with the Zookeeper installation script that prevented upgrades from being performed after the initial boot.

# Release 1.13.7

Fixed an issue with EMR Configuration where disabling logs and metric will not correctly propagate to the EMR cluster.

This will require replacing the EMR cluster. Expect 10-15 minutes of downtime for pipelines. The API and Web UI will be unaffected.

# Release 1.13.6

Adds permissions to read from Etleap's deployment specific GitHub SQS queue, to deliver GitHub webhooks for dbt CI.

# Release 1.13.5

- Fixes an issue that caused the system clocks on the App and Zookeeper EC2 instances to fall out of sync after upgrading to Ubuntu 24.04 in 1.13.0.
- Upgrades RDS storage class from `gp2` to `gp3`.
- Resolves an issue in version 1.13.4 that caused `terraform apply` to fail due to a missing `iops` variable for RDS instances using gp3 volumes. 
- The module now ignores changes to `target_on_demand_capacity` for EMR instance fleets, so manual changes by operators or automatic changes by the application do not cause Terraform drift.

## Upgrade instructions

The upgrade to RDS is performed without downtime of the database, but it will affect database performance for up to 12 hours after the change.
We recommend performing this upgrade during periods with low activity, e.g. overnight or during weekends.

This upgrade will also replace the application and Zookeeper EC2 instances, and this will cause about 15 minutes of downtime.
If your AWS policies block AMIs by default, please whitelist the AMI for your deployment's region before applying:

af-south-1: ami-00c3d948804bc9ac0
ap-east-1: ami-04900dbefe52f0292
ap-northeast-1: ami-03b4e26264e79e1b3
ap-northeast-2: ami-04d8c19ce85bf7bc4
ap-south-1: ami-05b4d805e813a75a3
ap-southeast-1: ami-0ed4ad5c849aae7fe
ap-southeast-2: ami-07950cf97c5b22ecd
ca-central-1: ami-015345ee32700d712
eu-central-1: ami-0f3c0b99dee438443
eu-north-1: ami-04769c93e87653487
eu-south-1: ami-04889e7fd638ca39b
eu-west-1: ami-01d7ca7d503247c4a
eu-west-2: ami-0eb8840519b09339f
eu-west-3: ami-07f529eb42ada0d59
me-south-1: ami-017505227fb051406
sa-east-1: ami-0759355ae132089e2
us-east-1: ami-0e0a4106402da2799
us-east-2: ami-079378cd1a0c35a49
us-west-1: ami-0047b1dbf7c01e21f
us-west-2: ami-0f4ef8559c70234eb

1. Change the module version to `1.13.5` and add the following property to the module definition:
   ```
   rds_apply_immediately = true
   ```
2. Run `terraform apply` to upgrade the DB storage type and replace the Application and Zookeeper instances.
3. Once the previous step is complete, remove the `rds_apply_immediately` variable and run `terraform apply` again.

# Release 1.13.4 (Withdrawn)

This version has been withdrawn due to a missing required RDS variable. The issue has been resolved in version 1.13.5. Please use version 1.13.5 or later instead.

# Release 1.13.3

Fixes an issue introduced in version 1.13.2 where the IAM role used by EMR was missing the new IAM policy to access Amazon Cognito.

# Release 1.13.2

Adds an Amazon Cognito identity pool resource in order to support Microsoft Entra ID identity federation. There is no charge for this AWS resource.

# Release 1.13.1

Fixes an issue introduced in version 1.12.9 that caused oscillating Terraform plans for the additional monitoring rules added in that release. 
This issue only affects AWS accounts with more than one Etleap VPC deployment.

# Release 1.13.0

Upgrades the Application and Zookeeper EC2 instances to use Ubuntu 24.04 LTS.

## Upgrade instructions

This upgrade will replace the application and Zookeeper EC2 instances, and this will cause about 15 minutes of downtime.
If your AWS policies block AMIs by default, please whitelist the AMI for your deployment's region before applying:

af-south-1: ami-02cb3e4084f9ce0ba
ap-east-1: ami-0fdaff15803e47630
ap-northeast-1: ami-02ad584f3f0b7fa08
ap-northeast-2: ami-0973b9699cae043e0
ap-south-1: ami-0b9db28497f390dfc
ap-southeast-1: ami-08be11789fd91b5dc
ap-southeast-2: ami-0ee526f6ebcc05b45
ca-central-1: ami-0f9d27516ce5dd62c
eu-central-1: ami-0af8da5d15f2d73b2
eu-north-1: ami-06d85b0fb796725d3
eu-south-1: ami-05b2089088824e498
eu-west-1: ami-0e7a71a279e5e3195
eu-west-2: ami-02c0dda056afbbbfc
eu-west-3: ami-0c6ed391eaa94a3cd
me-south-1: ami-09cf190512458a456
sa-east-1: ami-0d4dcfdd604ad4f00
us-east-1: ami-01a5f88b519cc1804
us-east-2: ami-0470f71d9b27d37c5
us-west-1: ami-03148d94d3f13d5ad
us-west-2: ami-0a7bf5a0b2820c543

# Release 1.12.9

Adds monitoring to capture EMR spot capacity shortage events, enabling the automatic switching to on-demand instances when spot capacity is unavailable.

# Release 1.12.8

Fixes EMR startup failures in some regions by excluding EC2 instance types not supported there.
This release makes no infrastructure changes.

# Release 1.12.7

Fixes an issue where the post-install script was not being executed on Zookeeper instances when the `post_install_script` variable, introduced in 1.12.1, was set.
This release adds a minimal permission for Zookeeper EC2 instances to correctly fetch the post-install script from the `init-scripts` directory in the intermediate bucket.

# Upgrade instructions

1. Update the module version to `1.12.7` and run `terraform apply`.
2. If you have set the `post_install_script` variable, you will need to replace the Zookeeper instances to rerun the post-install script for them,
see [Upgrading the Zookeeper Cluster](./README.md#upgrading-the-zookeeper-cluster). 

# Release 1.12.6
Refactors the app node user-data to reduce its length to avoid certain deployments reaching the user-data length limit of 16k characters.
This is done by storing the RDS database initialization script in S3, instead of including it in the instance `user_data`, and fetching it on EC2 instance startup.

Note: This change is a refactoring only and no functional or behavioural changes are introduced by this version.

## Upgrade instructions

As part of this upgrade, the application instances will be replaced. This will cause about 15 minutes of downtime for the Web UI, API and pipeline processing.

# Release 1.12.5

This release upgrades EMR to version 5.36.2, and upgrades the instance fleet to only use 6th and 7th generation EC2 instance types.

Note that with EMR version 5.36.2 onwards, when an EMR cluster is replaced, it will automatically use the latest default patch version for the Amazon Linux 2 AMI. 
You can check the latest patch version in the [Amazon Linux 2 release notes](https://docs.aws.amazon.com/AL2/latest/relnotes/relnotes-al2.html).

## Upgrade instructions

This upgrade will replace the EMR cluster, which will cause about 10-15 minutes of downtime for pipelines. The API and Web UI will be unaffected.

# Release 1.12.4

1. The module now ignores changes to `allocated_storage` on the DMS replication instance created by the module when `disable_cdc_support` is false, so operators can increase disk space manually without triggering Terraform drift.
2. Renames the CloudWatch alarm from `DMS Disk Space 30GB Remaining` to `DMS Disk Space 125GB Remaining`, as the threshold was raised in version 1.10.6 but the name hadn’t been updated.

# Release 1.12.3

Adds the missing `GenerateDataKey` permission for the EMR cluster to encrypt data using the KMS key created by the module. This permission was missed as part of the changes in release 1.9.0.

Note: EMR does not have permission to decrypt data using the key.

# Release 1.12.2

Fixes an issue introduced in version 1.12.0 where a disk partition is not resized when the underlying EBS volume is larger than the one specified in the AMI.

## Upgrade instructions

As part of this upgrade, the application instances will be replaced. This will cause about 15 minutes of downtime for the Web UI, API and pipeline processing.

# Release 1.12.1

Introduced a new optional variable `post_install_script` to allow specifying a custom post-installation script to be executed during initial EC2 instance startup.
See [Custom Post-Installation script](./README.md#custom-post-installation-script) for more details.

# Release 1.12.0

This release enables encryption for all EBS volumes used by EC2 instances created by the module. This includes the EMR cluster, NAT, application instances, and Zookeeper instances.
The EBS volumes have been upgraded to `gp3` from `gp2`, and the size of the root volumes have been increased to 32GB from 8GB. 
EMR local disk encryption is enabled for the EMR cluster, and this uses a new KMS key created by the module.

## Upgrade instructions

As part of this upgrade, the NAT instance, EMR cluster, application instances and zookeeper instances will be replaced. This will cause about 30 minutes of downtime.

1. The `amis` variable is now deprecated. If you have specified it, please remove it from your module definition.
2. Update the module version to `1.12.0` and run `terraform apply`.

# Release 1.11.6

Release 1.11.1 updated the user data of Zookeeper instances so new instances would start up correctly. However, it also caused existing instances to be replaced, which isn't necessary and led to extra upgrade effort. This update prevents the need for replacement. 

# Release 1.11.5

Update the README documentation to no longer advise that the EBS volume is increased in response to any 90% disk usage alarms, as there is no way to do this in the module.

This is a documentation change only.

# Release 1.11.4

1. Adds support for [dbt CI](https://docs.etleap.com/docs/documentation/7yh44n1fjs24w-git-hub-pr-checks) by adding infrastructure for receiving GitHub webhooks. This includes an API Gateway and an SQS queue. The API Gateway's domain name can optionally be customized via the new `github_webhooks_domain_name_and_certificate` variable. See [usage instructions](./README.md#github-webhooks-url). 

2. Broadens the scope of resource permissions for Kinesis stream management from streams prefixed by `etleap-{deployment_id}-dms-` to streams prefixed by `etleap-{deployment_id}-` to enable using Kinesis streams for purposes other than DMS output, in particular the new SQS queue source integration. Also adds the `ListStreams`, and `DeleteStream` permission for streams with the same prefix so they can be listed and deleted when they are no longer in use.

3. Fixed a critical issue in the `cloud-init` configuration that prevented Zookeeper nodes from starting up. This issue was caused by a recent upgrade to a required Linux package (GRUB2).

# Release 1.11.3 (Withdrawn)

This version has been withdrawn due to a GitHub webhooks configuration issue. The issue has been resolved in version 1.11.4. Please use version 1.11.4 or later instead.

# Release 1.11.2 (Withdrawn)

This version has been withdrawn due to an invalid IAM policy specification. The issue has been resolved in version 1.11.3. Please use version 1.11.3 or later instead.

# Release 1.11.1 (Withdrawn)

This version has been withdrawn due to a GitHub webhooks configuration issue. The issue has been resolved in version 1.11.4. Please use version 1.11.4 or later instead.

# Release 1.11.0 (Withdrawn)

This version has been withdrawn due to a GitHub webhooks configuration issue. The issue has been resolved in version 1.11.4. Please use version 1.11.4 or later instead.

# Release 1.10.18

Adds a VPC gateway endpoint to route S3 traffic through. This reduces the network load on the NAT instance without incurring additional costs. This only applies to Etleap deployments where the module has created the VPC, i.e. `vcp_id` was not provided as input to the module.

# Release 1.10.17

Added a critical alarm named `Database extractor is running` that triggers when the application that runs database extractions is down. This situation affects all pipelines that extract from a database sources. This is a critical alarm. The remediation action is to contact Etleap's support team to help diagnose and address the issue.

# Release 1.10.16

Added a critical alarm named `NAT Network Saturation` that triggers when there is insufficient NAT bandwidth for the data pipeline workloads. When this alarm triggers the recommended action is to contact Etleap's support team, which will assist in discovering the root cause of the bandwidth issue and propose remediation steps.

# Release 1.10.15

Upgrades dbt from version 1.3, which has reached end of life, to version 1.9, which is the current latest version.

This upgrade requires replacement of the EMR cluster, which will cause 10-15 minutes of downtime to pipelines. The API and Web UI will be unaffected.

## Upgrade instructions

1. Update the module version to `1.10.15` and run `terraform apply`.
2. [Replace the EMR Cluster](/README.md#upgrading-the-emr-cluster).

# Release 1.10.14

Upgrades DMS to version 3.5.3, the current preferred version, as version 3.5.2 will reach end of life on March 25th, 2025. 

If you have `disable_cdc_support` set to `true`, there are no changes as part of this release. Otherwise, this will upgrade the DMS replication instance. Pipelines that have CDC enabled will experience an interruption of up to 20 minutes. All other pipelines, the Web UI, and the API will be unaffected by the upgrade.

# Release 1.10.13

## Changes
1. Upgrades the RDS instance to 8.0.40 as 8.0.32 is approaching its end of life date in March 2025.

2. Changes the default instance type for the DMS instance from `dms.t2.small` to `dms.t3.small` as T2 instances are being deprecated by AWS.
This will have no effect if the `disable_cdc_support` module variable is set to `true`, or if the `dms_instance_type` module variable is already explicitly set.

3. Adds support for schema changes and parsing errors in pipelines processed by [Apache Flink](https://flink.apache.org/) - currently those with [Apache Iceberg](https://iceberg.apache.org/) destinations - by adding an AWS Glue Catalog database for Etleap to store operational data. 

4. Adds the permissions required for the application to read from and write to the new AWS Glue Catalog database.

This release contains a DB upgrade. Please follow the steps below to ensure a safe upgrade. This will require up to 1 hour of downtime.

## Upgrade instructions
1. Don't update the module version until step 2 below.
   Add the following property to the module definition:
   ```
   app_available = false
   ```
   Run `terraform apply` to stop the app EC2 instances that access the database.
2. Change the module version to `1.10.13` and add the following property to the module definition:
   ```
   rds_apply_immediately = true
   ```
3. If the `dms_instance_type` module variable is already set to a C4, M4, R4, or T2 instance type, please update it to a C5, R5, R5, or T3 instance type respectively.
   Otherwise, the instance will automatically be upgraded by AWS, resulting in dirty Terraform state.
4. Run `terraform apply` to upgrade the DB and DMS versions.
5. Once the previous step is complete, remove the `app_available` and `rds_apply_immediately` variables and run `terraform apply` to bring the application back online.

# Release 1.10.12 (Withdrawn)

This version has been withdrawn due to a regression affecting pipelines with Apache Iceberg destinations. The issue has been resolved in version 1.10.13. Please use version 1.10.13 or later instead.

# Release 1.10.11 (Withdrawn)

This version has been withdrawn due to a regression affecting pipelines with Apache Iceberg destinations. The issue has been resolved in version 1.10.13. Please use version 1.10.13 or later instead.

# Release 1.10.10 (Withdrawn)

This version has been withdrawn due to a regression affecting pipelines with Apache Iceberg destinations. The issue has been resolved in version 1.10.13. Please use version 1.10.13 or later instead.

# Release 1.10.9

Adds permission for Etleap to describe Spot Instance Requests. This enables Etleap to track spot instances 
provisioned and de-provisioned for the deployment's EMR cluster, along with related information such as duration and termination reason.  

Also sets the minimum version of the Terraform AWS Provider to 5.73 to address [a bug where it does not detect removed/changed Security Group Rules](https://github.com/hashicorp/terraform-provider-aws/issues/39463).

# Release 1.10.8

Adds permissions for Etleap to import, manage, and remove CA certificates in DMS. This enables Etleap to automate SSL certificate verification for CDC-enabled database sources. There is no change if you have set `disable_cdc_support` to `true`.

# Release 1.10.7

Upgrades DMS instance version to 3.5.2 (the current preferred version). You can skip the upgrade procedure below if you have set `disable_cdc_support` to `true`.

Upgrade procedure:
1. Before changing the module version, set `app_available=false` and run `terraform apply` to stop the application instances.
2. Stop all DMS tasks via the AWS console.
3. Update module version and run `terraform apply`.
4. Resume all DMS tasks via the AWS console.
5. Set `app_available=true` and run `terraform apply` to bring up the application instances.

During the upgrade expect ~1 hour of downtime for the UI, API and pipelines.

# Release 1.10.6

Increases DMS storage to 250 GB from 50 GB to better handle large transactions. Also increases the alarm threshold to 125 GB.

Removed the optional, deprecated `downgrade_cdc` variable and associated DMS instance, as the version is no longer supported, and the underlying issue was addressed in the current version of DMS. 

# Release 1.10.5

Adds a new optional variable, `kms_key_additional_policies`, which allows specifying a list of additional KMS key policy statements to attach to the KMS key created by the module.

# Release 1.10.4

Fixes an issue which in rare cases could block Terraform operations when attempting to upgrade the module. This was resolved by removing some unused references to a load balancer.

# Release 1.10.3

Removes the need to have a secondary VPC for the Amazon Timestream for InfluxDB instance in some AWS regions, as AWS has recently expanded support for Timestream for InfluxDB. Applies to Etleap deployments in the following AWS regions: `ap-southeast-3`, `ca-central-1`, `eu-west-2`, `eu-west-3`, `eu-south-1`, `eu-south-2` and `me-central-1`.

# Release 1.10.2

Allows specifying a Security Group ID instead of a CIDR block as part of the the `outbound_access_destinations` configuration. 

# Release 1.10.1

Fixes a couple of bugs introduced in version 1.10.0:
1. An issue that prevents `terraform apply` from succeeding when the Influx DB database in a different region than the main deployment.
2. Duplicate security group rules errors when applying for a VPC that has `enable_streaming_ingestion` set to `true`.

# Release 1.10.0

Allows restricting outbound access to a set of specified CIDR blocks, ports and protocols; See documentation for the `outbound_access_destinations` variable for more details.

If your deployment has `enable_streaming_ingestion` set to `true`, please upgrade to 1.10.1 directly. The upgrade instructions below still apply.

## Upgrade instructions

If you encounter the following error, you'll need to a perform a manual rememdiation step:

```
│ Error: [WARN] A duplicate Security Group rule was found on (sg-098c7b89330fa0745). This may be
│ a side effect of a now-fixed Terraform issue causing two security groups with
│ identical attributes but different source_security_group_ids to overwrite each
│ other in the state. See https://github.com/hashicorp/terraform/pull/2376 for more
│ information and instructions for recovery. Error: operation error EC2: AuthorizeSecurityGroupEgress, https response error StatusCode: 400, RequestID: 8bf090ad-aafc-4651-a765-961f535d25c4, api error InvalidPermission.Duplicate: the specified rule "peer: 0.0.0.0/0, ALL, ALLOW" already exists
```

Remediation: identify the `EtleapApp`, `EtleapDms` and `EtleapEMR` security groups. For each of them, remove the Security Group rule that allow traffic to the `0.0.0.0/0` CIDR block, on all ports. There might be more than one. Then run `terraform apply` again to complete the update.

For more details, please see the original Terraform issue: https://github.com/hashicorp/terraform/pull/2376

# Release 1.9.5

Fixes an issue introduced in version 1.9.0 that broke deployments whose `deployment_id` input variable was longer than 11 characters. The issue was caused by Amazon Timestream for InfluxDB having a maximum instance name length of 40 characters. Reduces the Amazon Timestream for InfluxDB instance to maximum 40 characters and introduces validation to ensure `deployment_id` variable of 25 characters. The changes are backward compatible with all deployments, and upgrading to this from version 1.9.X is a no-op.

# Release 1.9.4

Fixes an issue introduced in version 1.9.0 that broke upgrades in AWS accounts with the default limit of 10 IAM policies per IAM role. We avoid hitting the limit by combining multiple policies into one.

# Release 1.9.3

Fixed an issue introduced in Release 1.9.0 with the creation and read order for the InfluxDB password. The issue occurred when running InfluxDB in a separate region, and required `terraform apply` to be run twice when creating a new VPC deployment.

# Release 1.9.2

Fixed an issue that would prevent the application from starting in VPCs whose CIDR range overlaps with `172.17.0.0/16`.

## Upgrade instructions

The upgrade will replace the 3 Zookeeper nodes, and application node(s). This will cause about 15 minutes of downtime for the UI, API and Pipelines.

# Release 1.9.1
Changes the way that the InfluxDB initialization script is obtained by the EC2 instances. This is to avoid some deployments hitting the 16k character limit for the `user_data` property. Instead of using the `user_data` property, the script is stored in S3 and fetched on EC2 instance startup.

# Release 1.9.0

Enables pipelines to [Apache Iceberg](https://iceberg.apache.org/) destinations. This version includes:
- An [Amazon Timestream for InfluxDB](https://docs.aws.amazon.com/timestream/latest/developerguide/timestream-for-influxdb.html) instance for storing metrics, along with a security group for Etleap's application node and EMR cluster to communicate with it.
- Permissions for Etleap to dynamically create Kinesis streams to store AWS DMS output.
- Permissions for Etleap's EMR cluster to read data from Etleap's Kinesis streams, and to use Etleap's KMS key to encrypt data.

## Upgrade instructions

This upgrade will replace the application node(s) and the EMR cluster, and this will cause about 30 minutes of downtime.
By default, this update requires Amazon Timestream for InfluxDB to be available in the region Etleap is deployed to, which is currently the following regions: `us-east-1`, `us-east-2`, `us-west-2`, `ap-south-1`, `ap-southeast-1`, `ap-southeast-2`, `ap-northeast-1`, `eu-central-1`, `eu-west-1`, and `eu-north-1`. If you are deploying Etleap in a region that's not in this list, you will need to create a secondary VPC in one of these regions and peer the primary VPC to it. To do this, please follow the instructions in the README.

# Release 1.8.14

Adds the option to select a configuration that uses larger EMR task spot nodes, for environments that have a restricted range of IP addresses available.

## Upgrade instructions

The following only applies if you want to make use of the new variable: Apply the terraform module version upgrade first, before changing the newly introduced parameter. This will avoid the EMR cluster from entering an invalid state.

# Release 1.8.13

Upgrades RDS CA certificate to `rds-ca-rsa4096-g1`, as the `rds-ca-2019` CA certificate is approaching its expiry date. This change does not require a database reboot.

## Upgrade instructions
1. Set the `rds_apply_immediately` variable to `true`
2. Apply terraform
3. Unset the `rds_apply_immediately` variable or set it to `false`
4. Apply terraform again

# Release 1.8.12

Fixes an issue with the `DMS Freeable Memory <= 10%` alarm by correcting its threshold value to 10% regardless of the instance size. Before this change the alarm would always be in an ALARM state with the default instance size, because the threshold had a fixed value of 2GB.

# Release 1.8.11

Removes the `region` variable and the AWS provider block from the module, as per [HashiCorp's best practices](https://developer.hashicorp.com/terraform/language/modules/develop/providers). This enables the module to inherit provider properties from the root module's AWS provider, including the `region` property, which specifies which AWS region resources should be created in.

## Upgrade Instructions

Please remove the `region` variable as it no longer exists. If you are using this module in a region other than the default `us-east-1` region, please ensure you have an `aws` provider block in your root module that includes the `region` property: 

```terraform
provider "aws" {
  region = "xx-xxxx-x"
}
```

# Release 1.8.10

Adds an internal variable to control a setting for preemption of tasks in EMR's job scheduler. The default value for the setting remains unchanged, and this setting should only be changed if requested by Etleap's support team.

# Release 1.8.9

1. Updates the EMR Cluster ID parameter name, so it follows the naming convention for the exiting parameters.
2. Adds a `Name` tag to the `zookeeper` Security Group for new deployments only. 

## Upgrade instructions

This update requires reprovisioning the application EC2 instances. Expect 15 minutes of downtime of the UI, API and pipelines. 

# Release 1.8.8

Adds permissions for Etleap's Support Role to read logs to troubleshoot EMR issues. When `allow_iam_support_role` is `true`, an IAM permission is set to allow Etleap's Support Role read access to the `emr-logs` folder in the S3 bucket that stores EMR logs.

# Release 1.8.7

Adds a workaround for [an AWS Terraform provider bug](https://github.com/hashicorp/terraform-provider-aws/issues/34661) that arises when re-creating the `High Job GC Activity` CloudWatch alarm, by calculating the app node's private hostname instead of retrieving it from AWS.

# Release 1.8.6

Fixes an issue introduced in version 1.8.0. When `app_available` is set to `false`, the resource `aws_iam_policy.support_ssm_limited` can't be created because it uses the `instance_id` field of the app node, which doesn't exist. This fixes that issue by making the resource `aws_iam_policy.support_ssm_limited` conditional on `app_available`.

# Release 1.8.5

Removes the `github_access_token` variable as it was not used, `github_access_token_arn` is used instead.

# Release 1.8.4

Locks database CA certificate to `rds-ca-2019`, as the application is not yet adapted for newer certificates and will fail to start due to new AWS defaults.

# Release 1.8.3

Grants the `dms:ModifyEndpoint` to the `EtleapApp` role so that it can update the connection details on DMS endpoints when source connections for CDC pipelines are changed in Etleap.

# Release 1.8.2

Remove the database creation script and other related resources related to the deprecated Salesforce V1 connector, as the migration to new Salesforce V2 connector has been completed for all environments.

This release will require replacing the application EC2 instances. Expect 15 minutes of downtime for pipelines, API and WebApp. 

# Release 1.8.1

Resolved [an issue related to Zookeeper Transaction ID (zxid) exhaustion](https://issues.apache.org/jira/browse/ZOOKEEPER-2789) that could cause Zookeeper cluster downtime.

More details: zxid is a unique, sequential identifier assigned to each transaction in a Zookeeper cluster, ensuring the orderly execution and consistency of distributed operations. It has a maximum value of 2^32, and the Zookeeper cluster gets into a bad state when the zxid reaches this value. The solution is to periodically trigger leader re-election in the Zookeeper cluster before the zxid counter values reach its maximum limit. Restarting the leader resets the zxid counter to 0, and the cluster continues to operate normally without any downtime.

## Upgrade Instructions
This version requires replacement of the Zookeeper EC2 instances. Sequential replacement of each instance ensures zero downtime.

```bash
terraform taint 'module.<name>.aws_instance.zookeeper["1"]'
terraform apply
terraform taint 'module.<name>.aws_instance.zookeeper["2"]'
terraform apply
terraform taint 'module.<name>.aws_instance.zookeeper["3"]'
terraform apply
```

# Release 1.8.0

## Summary

New Support Role for Etleap access to the deployment that Etleap's support team can assume along with limited IAM policies for providing support.

## Changes

New variable `allow_iam_support_role` that controls whether this role is created or not. If set to `false`, this role will not be created.

Support Role limited IAM policies include:
- Start, stop, and resume Port Forwarding to the DB (RDS) instance and SOCKS proxy (using SSM sessions) specifically using the `Etleap App main` instance
- Describing EC2 instances, network interfaces, images, addresses, subnets, tags, and volumes
- Listing resources related to Auto Scaling, EMR, CloudWatch, RDS, SNS, and Support
- Listing SNS topics and queues related to the Etleap deployment
- Listing and reading metric data from CloudWatch
- Allows reading a specific AWS Secrets Manager secret: the DB support user password
- Allows reading AWS Parameter Store parameters specific to this deployment

These policies are also included if CDC is enabled: (in case `disable_cdc_support` is not false)
- Accessing and filtering logs to the specific DMS CloudWatch log group
- Listing resources related to DMS
- Allows specific write actions to DMS resources, including creating and deleting endpoints, replication tasks, and assessments

## Upgrade Instructions

If you currently have explicitly set `disable_ssm_access` to `true`, please remove this variable as it no longer exists. In this case, if you wish to disable Etleap support access, please set `allow_iam_support_role` to `false`.

# Release 1.7.8

Tunes `DMS Disk Space 30GB Remaining` alarm to reduce flappiness.

# Release 1.7.7

Fix an issue with the Zookeeper installation that prevented the Zookeeper cluster from starting up propertly. The issue was introduced in version 1.7.6.

# Release 1.7.6

Pin Docker to v24.0.7 and docker-compose to v1.25.0. This fixes an issue where newer Docker engine version (25) was not compatible with docker-compose v1.

# Release 1.7.5

Use the latest Etleap NAT image, automatically discovered from the AMI catalog. This fixes an issue where the NAT image ID was hardcoded.

## Upgrade Instructions
Before applying, please remove the variable `amis["nat"]` if you have defined it.

# Release 1.7.4

Limiting EMR Task Spot Instance sizes to `4xlarge`. This addresses increased rates of tranformation errors we saw with the larger instance types. 

## Upgrade Instructions

This update will require replacing the EMR cluster, and this will cause 15-20 minutes of downtime to pipelines. The API and Web UI will be unaffected.

Run `terraform apply -replace=module.<name>.aws_emr_cluster.emr` to replace the EMR cluster.

# Release 1.7.3
Removes `emr_task_node_instance_type` and `emr_task_node_bid_price` variables as they are no longer used.

# Release 1.7.2
Fixes RDS CPU, disk and freeable memory alarms, which broke due to Terraform AWS provider upgrade (Release 1.7.0).

# Release 1.7.1
Upgrades DMS instance version to 3.5.1.

Upgrade procedure:
1. Before changing the module version, set `app_available=false` and run `terraform apply` to stop the application instances.
2. Stop all DMS tasks via the AWS console.
3. Update module version and run `terraform apply`.
4. Resume all DMS tasks via the AWS console.
5. Set `app_available=true` and run `terraform apply` to bring up the application instances.

During the upgrade expect ~1 hour of downtime for the UI, API and pipelines.

# Release 1.7.0


## Summary
Switches the EMR cluster from using instance groups to instance fleets. This provides greater resilience to Spot Instance shortages. 

## Changes
- The EMR cluster will be provisioned with Instance Fleets for Master, Core and Task nodes.
- The `EtleapEMR_AutoScaling_DefaultRole` will be deleted. Scaling the cluster will done by the Etleap application.
- The `EtleapApp` role now has the `elasticmapreduce:ListInstanceFleets` and `elasticmapreduce:ModifyInstanceFleet` permissions, so it can perform scaling operations.
- The `EtleapEMRProfilePolicy` role now has the `elasticmapreduce:ListInstanceFleets` permission instead of `elasticmapreduce:ListInstanceGroups`.
- The `EtleapEMRInstanceFleet` policy is now attached to the EMR default role (`EtleapEMR_DefaultRole`). It allow the role to be passed to EC2, as well as granting the `ec2:CreateLaunchTemplateVersion` permission. These are required for EMR so it can provision resources when starting up the instance fleets.
- Adds a new `EtleapEmrClusterId` SSM parameter.
- Updates the required Terraform AWS Provider to version 5.28 or higher. 

## Upgrade Instructions
Before applying, please run `terraform init -upgrade` to get the new version of the AWS provider. 

This version will require both the App EC2 instances, and the EMR cluster to be replaced. Expect a 15 minute downtime for the Web UI, API and Pipeline operation when applying. 

# Release 1.6.22

Remove search for AWS's NAT image, as it has been removed from their catalog (although the image still exists), causing Terraform to fail when trying to apply. The NAT image ID is hardcoded for now, and we will provide a new image soon.

# Release 1.6.21

Fixing the RDS CPU alarm threshold. Setting it to the correct value of 90%, instead of the current value of 100%. 

# Release 1.6.20

When running health checks for the streaming ingestion infrastructure, use the load balancer's DNS address rather than a private IP address. This change is because the private IP address might change at any time.

Updated the AWS provider minimum version to 4.59, to support deletion protection when creating/updating a DynamoDB table.

# Release 1.6.19

Upgrading the EMR Core nodes from `c5.xlarge` to `r5.xlarge` to prevent cluster failures due to memory pressure on the Core nodes.

Core nodes will run both Hadoop's file system (HDFS) and Map-Reduce or Spark jobs. Because of this, they require more memory than TASK nodes, which only run Map-Reduce or Spark jobs.

This change will reprovision the EMR cluster. Expect about 15 minutes of downtime, while the new cluster starts up.

# Release 1.6.18

Always granting `ssm:GetParameter` privileges to the `EtleapApp` role, so it can read parameters with the `etleap/` prefix. This fixes an issue introduced in v1.5.6 where the containers will not start if `disable_ssm_access` is set to `true`.
