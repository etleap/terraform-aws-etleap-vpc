output "app_public_address" {
  value = aws_lb.app.dns_name
}

output "s3_input_role_arn" {
  value       = length(var.s3_input_buckets) > 0 ? aws_iam_role.s3_input_role[0].arn : null
  description = "Role to use when setting up \"S3 Input\" connections with a bucket from a different AWS account."
}

output "s3_input_bucket_policy" {
  value = {
    for bucket in var.s3_input_buckets :
    bucket => templatefile("${path.module}/templates/input-bucket-policy.tmpl", {
      account = data.aws_caller_identity.current.account_id,
      bucket  = bucket
    })
  }
  description = "Policies that need to applied to the S3 buckets specified by 's3_input_buckets' so Etleap's role can read from them."
}

output "setup_password" {
  sensitive   = true
  value       = module.setup_password.secret_string
  description = "The password to log into Etleap for the first time. You'll be prompted to change it after on first login."
}

output "public_subnet_a" {
  value = local.subnet_a_public_id
}

output "public_subnet_b" {
  value = local.subnet_b_public_id
}

output "private_subnet_a" {
  value = local.subnet_a_private_id
}

output "private_subnet_b" {
  value = local.subnet_b_private_id
}

output "public_route_table_id" {
  value = var.vpc_id == null ? aws_route_table.public[0].id : "Not managed by this Module"
}

output "private_route_table_id" {
  value = var.vpc_id == null ? aws_route_table.private[0].id : "Not managed by this Module"
}

output "vpc_id" {
  value = local.vpc_id
}

output "emr_cluster_id" {
  value = aws_emr_cluster.emr.id
}

output "intermediate_bucket_id" {
  value = aws_s3_bucket.intermediate.id
}

output "deployment_id" {
  value = var.deployment_id
}

output "main_app_ip" {
  value       = module.main_app.app_public_ip_address
  description = "The IP of the main application instance."
}

output "main_app_instance_id" {
  value       = module.main_app.instance_id
  description = "The instance ID of the main application instance."
}
