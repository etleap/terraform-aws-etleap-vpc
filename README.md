Contains templates for Etleap VPC deployments.

## CloudWatch Alarms

This module defines a number of CloudWatch alarms that can be used to alert your infrastructure operations team when the deployment is in a bad state. The table below describes the alarms that are defined, together with the action recommended to remedy them. Critical alarms are for conditions that cause pipelines to stop.

| Alarm | Critical | Cause | Resolution |
|---|---|---|---|
| EMR Cluster Running | Yes | EMR cluster is not running | Run terraform to reprovision a new cluster |
| 60% Disk EMR HDFS | No | Not enough core nodes for the workload | Increase the number of core nodes via the console or Terraform |
| EMR Unhealthy Nodes | No | EMR cluster is in a bad state | Taint the cluster and apply using Terraform |
| EMR Missing Blocks | No | Missing HDFS blocks means we lost one or more core nodes | Taint the cluster and apply using Terraform |
| RDS CPU 90% | No | RDS instance is saturating CPU | Increase the RDS instance size |
| RDS Disk Space | Yes | RDS is running out of disk space | Increase the `allocated_storage` via Terraform, or via the console |
| RDS Freeable Memory | No | RDS is running out of disk space | Increase the `allocated_storage` via Terraform, or via the console |
| * Node 80% CPU | No | CPU usage is consistently high on the specified instance | Upgrade the instance type to a larger one, or one of a newer generation, if available |
| * 90% Disk * | Yes | Disk is getting full for one of the instances | Increase the EBS size of the attached volumes; contant Etleap Support to diagnose to root cause |
