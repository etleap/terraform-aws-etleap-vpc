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
