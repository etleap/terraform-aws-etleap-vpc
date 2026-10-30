locals {
  msk_kms_key_arn = var.msk_kms_encryption_key == null && !var.disable_cdc_support && var.enable_msk_cluster ? aws_kms_key.msk[0].arn : var.msk_kms_encryption_key
}

resource "aws_kms_key" "msk" {
  count                   = var.disable_cdc_support || !var.enable_msk_cluster || var.msk_kms_encryption_key != null ? 0 : 1
  tags                    = merge({ Name = "Etleap-${var.deployment_id}-MSK-KMS-Key" }, local.default_tags)
  description             = "Etleap MSK encryption key"
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow MSK service to use the key"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_msk_configuration" "etleap_msk_config" {
  count          = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  name           = "etleap-${var.deployment_id}-msk-config"
  kafka_versions = []

  // Setting the max record size to 36MiB. We need to support large json lobs of up to 32 MiB
  // and DMS escapes json strings before outputting to kafka. Therefore, we are including 4MiB as headroom.
  server_properties = <<-EOT
    auto.create.topics.enable=true
    num.partitions=1
    log.cleanup.policy=delete
    message.max.bytes=37748736
    replica.fetch.max.bytes=37748736
  EOT
}

resource "aws_cloudwatch_log_group" "msk" {
  count             = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  tags              = local.default_tags
  name              = "msk-etleap-${var.deployment_id}"
  retention_in_days = 7
}

resource "aws_msk_cluster" "etleap" {
  count                  = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  tags                   = local.default_tags
  cluster_name           = "etleap-${var.deployment_id}-msk"
  kafka_version          = "3.9.x.kraft"
  number_of_broker_nodes = 3
  enhanced_monitoring    = "DEFAULT"

  broker_node_group_info {
    instance_type = var.msk_instance_type
    client_subnets = [
      local.subnet_a_private_id,
      local.subnet_b_private_id,
      local.subnet_c_private_id,
    ]
    security_groups = [
      aws_security_group.msk[0].id
    ]

    connectivity_info {
      public_access {
        type = "DISABLED"
      }
    }
  }

  client_authentication {
    sasl {
      iam   = true
      scram = true
    }
    unauthenticated = false
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = local.msk_kms_key_arn
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.etleap_msk_config[0].arn
    revision = aws_msk_configuration.etleap_msk_config[0].latest_revision
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = false
      }
      node_exporter {
        enabled_in_broker = false
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk[0].name
      }
      firehose {
        enabled = false
      }
      s3 {
        enabled = false
      }
    }
  }
}

resource "aws_security_group" "msk" {
  count       = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  tags        = merge({ Name = "Etleap-${var.deployment_id}-MSK" }, local.default_tags)
  name        = "Etleap-${var.deployment_id}-MSK"
  description = "Allows DMS, EMR, and App access to MSK"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "msk-ingress-9096-dms" {
  count                    = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  type                     = "ingress"
  from_port                = 9096
  to_port                  = 9096
  protocol                 = "tcp"
  security_group_id        = aws_security_group.msk[0].id
  source_security_group_id = aws_security_group.dms[0].id
  description              = "SASL/SSL (used by DMS as it does not support IAM auth for MSK)"
}

resource "aws_security_group_rule" "msk-ingress-9098-emr" {
  count                    = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  type                     = "ingress"
  from_port                = 9098
  to_port                  = 9098
  protocol                 = "tcp"
  security_group_id        = aws_security_group.msk[0].id
  source_security_group_id = aws_security_group.emr.id
  description              = "SASL/IAM auth over TLS (used by EMR / Flink CDC jobs)"
}

resource "aws_security_group_rule" "msk-ingress-9098-app" {
  count                    = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  type                     = "ingress"
  from_port                = 9098
  to_port                  = 9098
  protocol                 = "tcp"
  security_group_id        = aws_security_group.msk[0].id
  source_security_group_id = aws_security_group.app.id
  description              = "SASL/IAM auth over TLS (used by app / job role)"
}

resource "aws_security_group_rule" "msk-egress" {
  count             = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.msk[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "random_password" "msk_scram" {
  count   = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "msk_scram_dms" {
  count      = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  tags       = local.default_tags
  // Secret names must have the prefix 'AmazonMSK_' to be associated with an MSK cluster
  name       = "AmazonMSK_Etleap-${var.deployment_id}-MskDmsPassword"
  kms_key_id = local.msk_kms_key_arn
}

resource "aws_secretsmanager_secret_version" "msk_scram_dms" {
  count     = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  secret_id = aws_secretsmanager_secret.msk_scram_dms[0].id
  secret_string = jsonencode({
    username = "dms"
    password = random_password.msk_scram[0].result
  })
}

resource "aws_msk_scram_secret_association" "etleap_dms" {
  count           = var.disable_cdc_support || !var.enable_msk_cluster ? 0 : 1
  cluster_arn     = aws_msk_cluster.etleap[0].arn
  secret_arn_list = [aws_secretsmanager_secret.msk_scram_dms[0].arn]
}
