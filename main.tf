data "aws_caller_identity" "current" {}

locals {
  resource_name_suffix = var.unique_resource_names ? "-${var.deployment_id}-${random_id.deployment_random.hex}" : ""
}


module "elva" {
  count = var.enable_streaming_ingestion ? 1 : 0
  source = "./modules/elva"

  resource_name_suffix  = local.resource_name_suffix
  app_role_name         = aws_iam_role.app.name
  vpc_id                = local.vpc_id 
  key_name              = var.key_name
  subnet_a_id           = local.subnet_a_private_id
  subnet_b_id           = local.subnet_b_private_id
  load_balancer         = aws_lb.app
  app_listener_arn      = aws_lb_listener.app.arn
  region                = var.region
  config_bucket         = aws_s3_bucket.intermediate
  critical_cloudwatch_alarm_sns_topics = var.critical_cloudwatch_alarm_sns_topics
  non_critical_cloudwatch_alarm_sns_topics = var.non_critical_cloudwatch_alarm_sns_topics
}