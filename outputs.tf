output "app_public_address" {
  value = aws_lb.app.dns_name
}

output "streaming_endpoint_public_address" {
  value = var.enable_streaming_ingestion ? module.elva[0].elva_lb_public_address : null
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
  value       = local.subnet_a_public_id
  description = "The first public subnet for Etleap's VPC"
}

output "public_subnet_b" {
  value       = local.subnet_b_public_id
  description = "The second public subnet for Etleap's VPC"
}

output "private_subnet_a" {
  value       = local.subnet_a_private_id
  description = "The first private subnet for Etleap's VPC"
}

output "private_subnet_b" {
  value       = local.subnet_b_private_id
  description = "The second private subnet for Etleap's VPC"
}

output "public_route_table_id" {
  value       = var.vpc_id == null ? aws_route_table.public[0].id : "Not managed by this Module"
  description = "The public subnets' route table, if managed by the module"
}

output "private_route_table_id" {
  value       = var.vpc_id == null ? aws_route_table.private[0].id : "Not managed by this Module"
  description = "The public subnets' route table, if managed by the module"
}

output "vpc_id" {
  value       = local.vpc_id
  description = " The VPC ID where Etleap is deployed"
}

output "emr_cluster_id" {
  value       = aws_emr_cluster.emr.id
  description = "The ID of Etleap's EMR cluster"
}

output "intermediate_bucket_id" {
  value       = aws_s3_bucket.intermediate.id
  description = "The ID of Etleap's intermediate bucket"
}

output "deployment_id" {
  value       = var.deployment_id
  description = "The Deployment ID"
}

output "main_app_instance_id" {
  value       = var.app_available ? module.main_app[0].instance_id : null
  description = "The instance ID of the main application instance."
}

output "secondary_app_instance_id" {
  value       = var.ha_mode && var.app_available ? module.secondary_app[0].instance_id : null
  description = "The instance ID of the secondary application instance."
}

output "kms_policy" {
  value = var.s3_kms_encryption_key == null ? null : <<EOF
{
    "Sid": "Allow Etleap roles use of the key",
    "Effect": "Allow",
    "Principal": {
        "AWS": [
            "${aws_iam_role.app.arn}",
            "${aws_iam_role.emr.arn}",
            "${aws_iam_role.intermediate.arn}",
            "${aws_iam_role.emr_default_role.arn}"
        ]
    },
    "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
    ],
    "Resource": "${var.s3_kms_encryption_key}"
}
EOF
  description = "Statement to add to the KMS key if using a Customer-Manager SSE KMS key for encrypting S3 data."
}

output "kms_key_arn" {
  value = aws_kms_key.etleap_encryption_key.arn
}

output "zookeeper_private_ips" {
  value       = toset([ for i in aws_network_interface.zookeeper : i.private_dns_name ])
  description = "Zookeeper ensemble private ips"
}
