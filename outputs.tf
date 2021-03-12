output "app_public_address" {
  value = var.ha_mode ? aws_lb.app[0].dns_name : module.main_app.app_public_ip_address
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
    value       = module.setup_password.secret_string
    description = "The password to log into Etleap for the first time. You'll be prompted to change it after on first login."
}

output "public_subnet_a" {
  value = aws_subnet.a_public.id
}

output "public_subnet_b" {
  value = aws_subnet.b_public.id
}

output "private_subnet_a" {
  value = aws_subnet.a_private.id
}

output "private_subnet_b" {
  value = aws_subnet.b_private.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.etleap.id
}