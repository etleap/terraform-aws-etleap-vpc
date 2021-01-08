resource "aws_cloudwatch_metric_alarm" "emr_cluster_running" {
  alarm_name          = "${var.deployment_id} - EMR Cluster Running"
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
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "emr_hdfs_utilization" {
  alarm_name          = "${var.deployment_id} - 60% Disk EMR HDFS"
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
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "emr_unhealthy_nodes" {
  alarm_name          = "${var.deployment_id} - EMR Unhealthy Nodes"
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
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "emr_missing_blocks" {
  alarm_name          = "${var.deployment_id} - EMR Missing Blocks"
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
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.deployment_id} - RDS CPU 90%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db.id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "100"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "rds_disk" {
  alarm_name          = "${var.deployment_id} - RDS Disk Space"
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
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory" {
  alarm_name          = "${var.deployment_id} - RDS Freeable Memory"
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
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "main_node_cpu" {
  alarm_name          = "${var.deployment_id} - Main Node 80% CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = module.main_app.instance_id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "ha_node_cpu" {
  count               = var.ha_mode ? 1 : 0
  alarm_name          = "${var.deployment_id} - HA Node 80% CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = module.ha_app[0].instance_id
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "main_app_disk_root" {
  alarm_name          = "${var.deployment_id} - Main Node 90% Disk Root"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.main_app.instance_id
    Device     = "Root"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "main_app_disk_docker" {
  alarm_name          = "${var.deployment_id} - Main Node 90% Disk Docker"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.main_app.instance_id
    Device     = "Docker"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "ha_app_disk_root" {
  count               = var.ha_mode ? 1 : 0
  alarm_name          = "${var.deployment_id} - HA Node 90% Disk Root"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.ha_app[0].instance_id
    Device     = "Root"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "ha_app_disk_docker" {
  count               = var.ha_mode ? 1 : 0
  alarm_name          = "${var.deployment_id} - HA Node 90% Disk Docker"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disk"
  namespace           = "Etleap/EC2"
  dimensions = {
    InstanceId = module.ha_app[0].instance_id
    Device     = "Docker"
  }
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "90"
  alarm_actions             = var.cloudwatch_alarm_sns_topics
  ok_actions                = var.cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.cloudwatch_alarm_sns_topics
}
