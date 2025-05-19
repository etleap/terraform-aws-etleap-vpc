resource "aws_kms_key" "etleap_encryption_key" {
  tags                    = merge({Name = "Etleap KMS"}, local.default_tags)
  description             = "Etleap secrets encryption key"
  deletion_window_in_days = 30
  policy                  = templatefile("${path.module}/kms-policy.json", {
    account_id            = data.aws_caller_identity.current.account_id,
    resource_name_suffix  = local.resource_name_suffix,
    additional_policies   = var.kms_key_additional_policies
  })
}

resource "aws_kms_key" "etleap_emr_ebs_encryption_key" {
  tags                    = merge({ Name = "Etleap EMR EBS KMS" }, local.default_tags)
  description             = "Etleap EMR EBS encryption key"
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "emr-ebs-kms-policy",
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        Sid    = "AllowEMRRoleUseOfKey",
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.emr.arn,
            aws_iam_role.emr_default_role.arn
          ]
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ListGrants"
        ],
        Resource = "*",
      }
    ]
  })
}
