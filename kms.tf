resource "aws_kms_key" "etleap_encryption_key" {
  description             = "Etleap secrets encryption key"
  deletion_window_in_days = 30
  policy                  = templatefile("${path.module}/kms-policy.json", {
    account_id           = data.aws_caller_identity.current.account_id,
    resource_name_suffix = local.resource_name_suffix
  })

  tags = {
    Name = "Etleap KMS"
  }
}
