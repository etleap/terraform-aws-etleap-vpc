resource "aws_kms_key" "etleap_encryption_key_virginia" {
  description             = "Etleap secrets encryption key virginia region"
  deletion_window_in_days = 30
  policy                  = templatefile("${path.module}/kms-policy.json", {
    account_id    = data.aws_caller_identity.current.account_id,
    deployment_id = var.deployment_id,
    random_hex    = random_id.deployment_random.hex
  })

  tags = {
    Name = "Etleap KMS"
  }
}