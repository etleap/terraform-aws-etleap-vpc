data "aws_caller_identity" "current" {}

locals {
  resource_name_suffix = var.unique_resource_names ? "-${var.deployment_id}-${random_id.deployment_random.hex}" : ""

  temporary_enable_public_infra = false
}
