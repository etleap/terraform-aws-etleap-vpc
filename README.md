Contains templates for Etleap VPC deployments.

## CloudWatch Alarms

This module defines a number of CloudWatch alarms that can be used to alert your infrastructure operations team when the deployment is in a bad state. The table below describes the alarms that are defined, together with the action recommended to remedy them. Critical alarms are for conditions that cause pipelines to stop.

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
| * 90% Disk * | Yes | Disk is getting full for one of the instances | Increase the EBS size of the attached volumes; contant Etleap Support to diagnose to root cause |
| App is running | Yes | The main web application is down and not accepting requests | If in single-availability node, reprovision the instace. If in High-Availablity mode, reprovision both instances, and contact Etleap Support to determine the cause of the outage |

### Reprovisioning a new EMR cluster

If the `EMR Cluster Running`, `EMR Unhealthy Nodes` or `EMR Missing Blocks` alarm has triggered, you'll need to start a new EMR cluster.
Before running terraform, run the following script to send any relevant logs and metrics to Etleap for analysis (if you have the option enabled for you deployment).

```
CLUSTER_ID=$(terraform output -raw emr_cluster_id)
INTERMEDIATE_BUCKET=$(terraform output -raw intermediate_bucket_id)
DEPLOYMENT_ID=$(terraform output -raw deployment_id)
aws s3 cp s3://$INTERMEDIATE_BUCKET/emr-logs/$CLUSTER_ID/ s3://etleap-emr-vpc-logs/$DEPLOYMENT_ID/$CLUSTER_ID/ --acl bucket-owner-full-control --recursive
```

Once this is done, you can run `terrafrom apply` to recreate or replace the cluster, as the need may be.