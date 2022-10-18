resource "aws_cloudwatch_metric_alarm" "elva_healthyhosts" {
  alarm_name          = "Elva Healthy Host Count"
  comparison_operator = "LessThanThreshold"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  datapoints_to_alarm = "5"
  evaluation_periods  = "5"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "Number of healthy nodes in Target Group"
  alarm_actions             = var.critical_cloudwatch_alarm_sns_topics
  ok_actions                = var.critical_cloudwatch_alarm_sns_topics
  insufficient_data_actions = var.critical_cloudwatch_alarm_sns_topics
  dimensions = {
    TargetGroup  = aws_lb_target_group.elva.arn_suffix
    LoadBalancer = var.load_balancer.arn_suffix
  }
}