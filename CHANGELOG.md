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
