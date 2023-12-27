resource "aws_cloudwatch_metric_alarm" "emr_cluster_running" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - EMR Cluster Running"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CoreNodesRunning"
  namespace           = "AWS/ElasticMapReduce"
  dimensions = {
    JobFlowId = aws_emr_cluster.emr.id
  }
  period             = "300"
  statistic          = "Average"
  threshold          = "1"
  treat_missing_data = "breaching"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "emr_hdfs_utilization" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - 60% Disk EMR HDFS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "HDFSUtilization"
  namespace           = "AWS/ElasticMapReduce"
  dimensions = {
    JobFlowId = aws_emr_cluster.emr.id
  }
  period                    = "300"
  statistic                 = "Maximum"
  threshold                 = "60"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "emr_unhealthy_nodes" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - EMR Unhealthy Nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "MRUnhealthyNodes"
  namespace           = "AWS/ElasticMapReduce"
  dimensions = {
    JobFlowId = aws_emr_cluster.emr.id
  }
  period                    = "300"
  statistic                 = "Minimum"
  threshold                 = "0"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "emr_missing_blocks" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - EMR Missing Blocks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "MissingBlocks"
  namespace           = "AWS/ElasticMapReduce"
  dimensions = {
    JobFlowId = aws_emr_cluster.emr.id
  }
  period                    = "300"
  statistic                 = "Minimum"
  threshold                 = "0"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}


resource aws_cloudwatch_metric_alarm "emr_namenode_disk" {
  alarm_name          = "Etleap - ${var.deployment_id} - 80% Disk EMR NameNode"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = data.aws_instance.emr-master.id
    Device     = "NameNode"
  }
  period                    = "600"
  statistic                 = "Maximum"
  threshold                 = "80"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "Etleap - ${var.deployment_id} - RDS CPU 90%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db.id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "rds_disk" {
  alarm_name          = "Etleap - ${var.deployment_id} - RDS Disk Space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db.id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "15728640000"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory" {
  alarm_name          = "Etleap - ${var.deployment_id} - RDS Freeable Memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db.id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "524288000"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "main_node_cpu" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - Main Node 80% CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = module.main_app[0].instance_id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "secondary_node_cpu" {
  count               = var.app_available && var.ha_mode ? 1 : 0
  alarm_name          = "Etleap - ${var.deployment_id} - Secondary Node 80% CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = module.secondary_app[0].instance_id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "main_app_disk_root" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - Main Node 90% Disk Root"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.main_app[0].instance_id
    Device     = "Root"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "main_app_disk_docker" {
  count = var.app_available ? 1 : 0

  alarm_name          = "Etleap - ${var.deployment_id} - Main Node 90% Disk Docker"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.main_app[0].instance_id
    Device     = "Docker"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "secondary_app_disk_root" {
  count               = var.app_available && var.ha_mode ? 1 : 0
  alarm_name          = "Etleap - ${var.deployment_id} - Secondary Node 90% Disk Root"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.secondary_app[0].instance_id
    Device     = "Root"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "secondary_app_disk_docker" {
  count               = var.app_available && var.ha_mode ? 1 : 0
  alarm_name          = "Etleap - ${var.deployment_id} - HA Node 90% Disk Docker"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.secondary_app[0].instance_id
    Device     = "Docker"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "app_running" {
  alarm_name = "Etleap - ${var.deployment_id} - App is running"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "AppRunning"
  namespace           = "Etleap/EC2"
  dimensions = {
    "Deployment" = var.deployment_id
  }
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "job_running" {
  alarm_name = "Etleap - ${var.deployment_id} - Job is running"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "10"
  metric_name         = "JobRunning"
  namespace           = "Etleap/EC2"
  dimensions = {
    "Deployment" = var.deployment_id
  }
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "dms_cpu" {
  alarm_name                = "Etleap - ${var.deployment_id} - DMS 80% CPU"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/DMS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "dms_disk" {
  count               = var.disable_cdc_support ? 0 : 1
  alarm_name          = "Etleap - ${var.deployment_id} - DMS Disk Space 30GB Remaining"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/DMS"
  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.dms[0].id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "32212254720"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "dms_available_memory" {
  count                     = var.disable_cdc_support ? 0 : 1
  alarm_name                = "Etleap - ${var.deployment_id} - DMS Available Memory <= 10%"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "AvailableMemory"
  namespace                 = "AWS/DMS"
  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.dms[0].id
  }
  period                    = "300"
  statistic                 = "Average"
  // Memory size is in MiB, so we need to convert to bytes(1024*1024) and then take 10%(0.1) of that
  threshold                 = data.aws_ec2_instance_type.dms_instance_type.memory_size * 1024 * 1024 * 0.1
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "dms_freeable_memory" {
  count                     = var.disable_cdc_support ? 0 : 1
  alarm_name                = "Etleap - ${var.deployment_id} - DMS Freeable Memory <= 2GB"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/DMS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "2147483648"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "zookeeper_unhealthy_nodes" {
  for_each = local.zookeeper_map

  alarm_name                = "Etleap - ${var.deployment_id} - ${each.value} is down"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "10"
  metric_name               = "Ruok"
  namespace                 = "Etleap/ZooKeeper"
  dimensions = {
    Node = "zookeeper"
    Instance = "${each.value}"
  }
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "kinesis_running_main_app" {
  count = var.app_available ? 1 : 0

  alarm_name                = "Etleap - ${var.deployment_id} - main_app - Kinesis Agent not running"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "10"
  metric_name               = "AwsKinesisRunning"
  namespace                 = "Etleap/EC2"
  dimensions = {
    InstanceId = module.main_app[0].instance_id
    Deployment = var.deployment_id
  }
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "kinesis_running_secondary_app" {
  count = var.app_available && var.ha_mode ? 1 : 0

  alarm_name                = "Etleap - ${var.deployment_id} - secondary_app - Kinesis not running"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "10"
  metric_name               = "AwsKinesisRunning"
  namespace                 = "Etleap/EC2"
  dimensions = {
    InstanceId = module.secondary_app[0].instance_id
    Deployment = var.deployment_id
  }
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "job_gc" {
  count = var.app_available ? 1 : 0

  alarm_name                = "Etleap - ${var.deployment_id} - High Job GC Activity"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "10"
  threshold                 = "25"
  datapoints_to_alarm       = "10"
  treat_missing_data        = "missing"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics

  metric_query {
    id          = "e1"
    // this uses the same formula as the one in the Etleap_Ops dashboard
    expression  = "100*(((RATE(m1)+ABS(RATE(m1)))/2)/1000)"
    label       = "GC Stop-the-World Pct"
    return_data = true
  }

  metric_query {
    id          = "m1"

    metric {
      stat        = "Maximum"
      metric_name = "GC Stop-the-World Time"
      period      = "60"
      namespace   = "Etleap/Java"
      dimensions  = {
        local-hostname = module.main_app[0].instance_private_dns
        level          = "INFO"
        type           = "GAUGE"
        Env            = var.deployment_id
        id             = "gcMetrics"
        class          = "JVMMetricsService"
      }
    }
  }
}