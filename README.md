Contains templates for Etleap VPC deployments.

## CloudWatch Alarms

This templates defines a number of cloudwatch alarms, to alert the Ops team when the deployment is in a bad state.
The table below describe the alarms that are defined, together with the action needed to remedy them.

| Alarm | Cause | Resolution |
|---|---|---|
| EMR Cluster Running | EMR cluster is not running | Run terraform to reprovision a new cluster |
| 60% Disk EMR HDFS | Not enough core nodes for the workload | Increase the number of core nodes via the console or Terraform |
| EMR Unhealthy Nodes | EMR cluster is in a bad state | Taint the cluster and apply using Terraform |
| EMR Missing Blocks | Missing HDFS blocks means we lost one or more core nodes | Taint the cluster and apply using Terraform |
| RDS CPU 90% | RDS instance is saturating CPU | Increase the RDS instance size |
| RDS Disk Space | RDS is running out of disk space | Increase the `allocated_storage` via Terraform, or via the console |
| RDS Freeable Memory | RDS is running out of disk space | Increase the `allocated_storage` via Terraform, or via the console |