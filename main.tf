data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  region               = data.aws_region.current.name
  deployment_random    = random_id.deployment_random.hex
  resource_name_suffix = var.unique_resource_names ? "-${var.deployment_id}-${random_id.deployment_random.hex}" : ""
}

module "elva" {
  count  = var.enable_streaming_ingestion ? 1 : 0
  source = "./modules/elva"
  tags   = local.default_tags

  deployment_random                        = local.deployment_random
  resource_name_suffix                     = local.resource_name_suffix
  app_role_name                            = aws_iam_role.app.name
  vpc_id                                   = local.vpc_id
  key_name                                 = var.key_name
  subnet_a_public_id                       = local.subnet_a_public_id
  subnet_a_private_id                      = local.subnet_a_private_id
  subnet_b_public_id                       = local.subnet_b_public_id
  subnet_b_private_id                      = local.subnet_b_private_id
  region                                   = local.region
  config_bucket                            = aws_s3_bucket.intermediate
  deployment_id                            = var.deployment_id
  critical_cloudwatch_alarm_sns_topics     = var.critical_cloudwatch_alarm_sns_topics
  non_critical_cloudwatch_alarm_sns_topics = var.non_critical_cloudwatch_alarm_sns_topics
  app_security_group_id                    = aws_security_group.app.id
  streaming_endpoint_access_cidr_blocks    = var.streaming_endpoint_access_cidr_blocks
  # Default to the bundled ACM certificate if one is not provided. Amazon do not issue certificates under their own domain names.
  acm_certificate_arn                      = var.streaming_endpoint_acm_certificate_arn == null ? aws_acm_certificate.etleap[0].arn : var.streaming_endpoint_acm_certificate_arn
}