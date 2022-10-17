resource "aws_cloudwatch_metric_alarm" "elva_cpu" {
  alarm_name          = "Elva CPU 90%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.elva.name
  }
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_actions             = var.non_critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.non_critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.non_critical_cloudwatch_alarm_sns_topics
}

resource "aws_cloudwatch_metric_alarm" "fluentd_errors" {
  alarm_name                = "Elva FluentD Errors"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "15"
  datapoints_to_alarm       = "15"
  metric_name               = "fluentd_err.rate_1min"
  namespace                 = "Etleap/StreamingIngress"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "0.2"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
  treat_missing_data        = "missing"
}

resource "aws_cloudwatch_metric_alarm" "fluentd_ok" {
  alarm_name                = "Elva FluentD OK"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "3"
  datapoints_to_alarm       = "3"
  metric_name               = "fluentd_ok.rate_1min"
  namespace                 = "Etleap/StreamingIngress"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "0.02"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
  treat_missing_data        = "missing"
}

resource "aws_cloudwatch_metric_alarm" "elva_high_latency" {
  alarm_name                = "High Elva Latency"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "5"
  datapoints_to_alarm       = "5"
  metric_name               = "TargetResponseTime"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "5.0"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
  treat_missing_data        = "missing"
  dimensions = {
    LoadBalancer: var.load_balancer.arn_suffix
  }
}