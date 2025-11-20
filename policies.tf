resource "aws_iam_policy_attachment" "secrets" {
  name       = "Get Deployment Secret"
  roles      = [aws_iam_role.app.name, aws_iam_role.zookeeper.name]
  policy_arn = aws_iam_policy.get_secrets_and_params.arn
}

resource "aws_iam_policy_attachment" "app_various_limited" {
  name       = "Etleap App Specific Permissions"
  roles      = [aws_iam_role.app.name]
  policy_arn = aws_iam_policy.app_various_limited.arn
}

resource "aws_iam_policy_attachment" "cloudwatch_metric_data" {
  name       = "Etleap Get and Put Metric Data"
  roles      = [aws_iam_role.app.name, aws_iam_role.zookeeper.name]
  policy_arn = aws_iam_policy.cloudwatch_metric_data.arn
}

resource "aws_iam_policy_attachment" "assume_data_roles" {
  name       = "App and EMR assume data role"
  roles      = [aws_iam_role.app.name, aws_iam_role.emr.name, aws_iam_role.emr_default_role.name]
  policy_arn = aws_iam_policy.assume_data_roles.arn
}

resource "aws_iam_role_policy_attachment" "app-ssm" {
  count      = var.allow_iam_support_role ? 1 : 0
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "zookeeper-ssm" {
  count      = var.allow_iam_support_role ? 1 : 0
  role       = aws_iam_role.zookeeper.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "zookeeper_read_init_script" {
  role       = aws_iam_role.zookeeper.name
  policy_arn = aws_iam_policy.zookeeper_read_init_script_policy.arn
}

resource "aws_iam_role_policy_attachment" "zookepeer_assume_etleap_roles" {
  role       = aws_iam_role.zookeeper.name
  policy_arn = aws_iam_policy.assume_etleap_roles.arn
}

resource "aws_iam_role_policy_attachment" "emr-ssm" {
  count      = var.allow_iam_support_role ? 1 : 0
  role       = aws_iam_role.emr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "emr_profile_policy" {
  role       = aws_iam_role.emr.name
  policy_arn = aws_iam_policy.emr_profile_policy.arn
}

resource "aws_iam_instance_profile" "emr_profile" {
  name = "EtleapEMRProfile${local.resource_name_suffix}"
  tags = local.default_tags
  role = aws_iam_role.emr.name
}

resource "aws_iam_instance_profile" "zookeeper" {
  name = "Etleap-Zookeeper_iam_profile${local.resource_name_suffix}"
  tags = local.default_tags
  role = aws_iam_role.zookeeper.name
}

resource "aws_iam_role_policy_attachment" "emr_default_role" {
  role       = aws_iam_role.emr_default_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role_policy_attachment" "emr_default_instance_fleet" {
  role       = aws_iam_role.emr_default_role.name
  policy_arn = aws_iam_policy.emr_default_instance_fleet.arn
}

resource "aws_iam_role" "zookeeper" {
  tags               = local.default_tags
  name               = "Etleapzookeeper${local.resource_name_suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

lifecycle {
  ignore_changes = [name, description, tags]
}
}

resource "aws_iam_role" "emr" {
  tags               = local.default_tags
  name               = "EtleapEMR${local.resource_name_suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get_secrets_and_params" {
  tags   = local.default_tags
  name   = "EtleapEC2SecretsAndParams${local.resource_name_suffix}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.account_id}:secret:Etleap*",
                "arn:aws:secretsmanager:${local.region}:841591717599:secret:${var.deployment_id}/*"
            ]
        },
         {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/etleap*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "secretsmanager.${local.region}.amazonaws.com"
                }
            }
        }
    ]
}
EOF
}

# All app instance specific permissions that are not used by other instances
# Organized in a single policy to avoid breaching the 10 policy per role limit
resource "aws_iam_policy" "app_various_limited" {
  tags   = local.default_tags
  name   = "Etleap-${var.deployment_id}-App-Various-Limited-Policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EC2Describe",
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSpotInstanceRequests",
          "autoscaling:DescribeAutoScalingInstances",
          "elasticmapreduce:ListInstanceFleets",
          "elasticmapreduce:ModifyInstanceFleet"
        ],
        "Resource": [
          "*"
        ]
      },
      {
        "Sid": "InfluxDbApiTokenSecretPut",
        "Effect": "Allow",
        "Action": "secretsmanager:PutSecretValue",
        "Resource": "${local.context.influx_db_api_token_arn}"
      },
      {
        "Sid": "ListKinesisStreams",
        "Effect": "Allow",
        "Action": [
          "kinesis:ListStreams"
        ],
        "Resource": "*"
      },
      {
        "Sid": "ManageKinesisStreams",
        "Effect": "Allow",
        "Action": [
          "kinesis:ListShards",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:DescribeStream",
          "kinesis:PutRecord*",
          "kinesis:CreateStream",
          "kinesis:IncreaseStreamRetentionPeriod",
          "kinesis:DeleteStream"
        ],
        "Resource": [
            "arn:aws:kinesis:${local.region}:${data.aws_caller_identity.current.account_id}:stream/etleap-${var.deployment_id}-*"
        ]
      },
      {
        "Sid": "InitScriptsGet",
        "Effect":"Allow",
        "Action":[
          "s3:GetObject"
        ],
        "Resource":[
          "arn:aws:s3:::${aws_s3_bucket.intermediate.id}/init-scripts/*"
        ]
      },
      {
        "Sid": "DynamoDBTableAccess",
        "Effect": "Allow",
        "Action": [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        "Resource": [
          "${aws_dynamodb_table.activity-log.arn}",
          "${aws_dynamodb_table.activity-log.arn}/index/*"
        ]
      },
      {
        "Sid": "SnsAllowPublishToAny",
        "Effect": "Allow",
        "Action": "sns:Publish",
        "Resource": "*"
      },
      {
        "Sid": "GitHubWebhooksSqsGetReceiveDelete",
        "Effect": "Allow",
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ],
        "Resource": [
          "${module.github_webhooks.github_webhooks_queue.arn}",
          "arn:aws:sqs:us-east-1:841591717599:Etleap-${var.deployment_id}-github-app-webhooks-queue"
        ]
      }
    ]
}
EOF
}

resource "aws_iam_policy" "cloudwatch_metric_data" {
  tags   = local.default_tags
  name   = "EtleapMetricData${local.resource_name_suffix}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricData",
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "zookeeper_read_init_script_policy" {
  tags   = local.default_tags
  name   = "Etleap-${var.deployment_id}-Zookeeper-Init-Scripts-Read-Policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "InitScriptsGet",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.intermediate.id}/init-scripts/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "emr_profile_policy" {
  tags   = local.default_tags
  name   = "EtleapEMRProfilePolicy${local.resource_name_suffix}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "cloudwatch:*",
            "ec2:Describe*",
            "elasticmapreduce:Describe*",
            "elasticmapreduce:ListBootstrapActions",
            "elasticmapreduce:ListClusters",
            "elasticmapreduce:ListInstanceFleets",
            "elasticmapreduce:ListInstances",
            "elasticmapreduce:ListSteps",
            "rds:Describe*",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject",
            "s3:DeleteObject",
            "ec2:CreateVolume",
            "ec2:AttachVolume",
            "ec2:ModifyInstanceAttribute",
            "ec2:DeleteVolume",
            "ec2:CreateTags"
        ]
    }]
}
EOF
}

resource "aws_iam_policy" "assume_data_roles" {
  tags   = local.default_tags
  name   = "Etleap_assume_data_roles${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEtleapRoles",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::841591717599:role/*",
        "${aws_iam_role.intermediate.arn}"
      ]
    },
    {
      "Sid": "AllowOtherRoles",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": ${jsonencode(var.roles_allowed_to_be_assumed)}
    }
  ]
}
EOF
}

resource "aws_iam_policy" "assume_etleap_roles" {
  tags   = local.default_tags
  name   = "Etleap_assume_etleap_roles${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEtleapRoles",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::841591717599:role/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "emr_default_role" {
  tags               = local.default_tags
  name               = "EtleapEMR_DefaultRole${local.resource_name_suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "emr_default_instance_fleet" {
  tags   = local.default_tags
  name   = "EtleapEMRInstanceFleet${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {  
      "Sid": "PassRoleForEC2",  
      "Effect": "Allow",  
      "Action": "iam:PassRole",  
      "Resource": "${aws_iam_role.emr_default_role.arn}",  
      "Condition": {  
          "StringLike": {  
              "iam:PassedToService": "ec2.amazonaws.com*"  
          }  
      }
    },
    {  
      "Sid": "AllowCreateLaunchTemplate",  
      "Effect": "Allow",  
      "Action": "ec2:CreateLaunchTemplateVersion",  
      "Resource": "*" 
    }]
}
EOF
}

# Provides access to KMS hosted keys to encrypt data
resource "aws_iam_policy" "emr_kms_encryption_policy" {
  name   = "EtleapEMRKmsEncryptionPolicy${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "${aws_kms_key.etleap_encryption_key.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "emr_kms_encryption_policy" {
  role       = aws_iam_role.emr.name
  policy_arn = aws_iam_policy.emr_kms_encryption_policy.arn
}

resource "aws_iam_policy" "kinesis_emr_permissions_policy" {
  name = "EtleapEMRKinesisPermissionPolicy${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:ListShards",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:DescribeStream",
        "kinesis:PutRecord*"
      ],
      "Resource": [
          "arn:aws:kinesis:${local.region}:${data.aws_caller_identity.current.account_id}:stream/etleap-${var.deployment_id}-*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "kinesis_emr_permissions_policy" {
  name       = "EtleapEMRKinesisPermissionPolicy${local.resource_name_suffix}"
  roles      = [aws_iam_role.emr.name]
  policy_arn = aws_iam_policy.kinesis_emr_permissions_policy.arn
}

# Provides access to the EBS EMR KMS key to encrypt and decrypt the local disk
resource "aws_iam_policy" "emr_ebs_kms_encryption_policy" {
  name   = "EtleapEMREbsKmsEncryptionPolicy${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants"
      ],
      "Resource": [
        "${aws_kms_key.etleap_emr_ebs_encryption_key.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "emr_ebs_kms_encryption_policy_emr" {
  role       = aws_iam_role.emr.name
  policy_arn = aws_iam_policy.emr_ebs_kms_encryption_policy.arn
}

resource "aws_iam_role_policy_attachment" "emr_ebs_kms_encryption_policy_emr_default" {
  role       = aws_iam_role.emr_default_role.name
  policy_arn = aws_iam_policy.emr_ebs_kms_encryption_policy.arn
}

resource aws_iam_policy "cognito_open_id_token" {
  name   = "EtleapCognitoOpenIdToken${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CognitoIdentityPoolAccess",
      "Effect": "Allow",
      "Action": [
        "cognito-identity:GetOpenIdTokenForDeveloperIdentity",
        "cognito-identity:LookupDeveloperIdentity"
      ],
      "Resource": "${aws_cognito_identity_pool.etleap_azure_identity_pool.arn}"
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "cognito_open_id_token" {
  name       = "EtleapCognitoOpenIDTokenPolicy${local.resource_name_suffix}"
  roles      = [aws_iam_role.app.name, aws_iam_role.emr.name]
  policy_arn = aws_iam_policy.cognito_open_id_token.arn
}
