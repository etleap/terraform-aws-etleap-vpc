resource "aws_kms_key" "etleap_encryption_key" {
  tags                    = merge({Name = "Etleap KMS"}, local.default_tags)
  description             = "Etleap secrets encryption key"
  deletion_window_in_days = 30
  policy                  = templatefile("${path.module}/kms-policy.json", {
    account_id            = data.aws_caller_identity.current.account_id,
    resource_name_suffix  = local.resource_name_suffix
  })
}
