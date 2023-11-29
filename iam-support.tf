// Role Support allows to be assumed by support users from the account 841591717599 logged with active MFA
resource "aws_iam_role" "support" {
    count       = var.disable_iam_support_role ? 0 : 1
    name        = "Etleap-${var.deployment_id}-Role-Support"
    description = "Role for Etleap AWS Support Team"
    max_session_duration = 28800
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": [
              "arn:aws:iam::841591717599:root"
            ]
          },
          "Action": "sts:AssumeRole",
          "Condition": {
            "Bool": {"aws:MultiFactorAuthPresent": "true"},
            "StringLike": { "sts:RoleSessionName": "$${aws:username}" }
          }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "support" {
    count       = var.disable_iam_support_role ? 0 : 1
    role       = aws_iam_role.support[0].name
    policy_arn = aws_iam_policy.support[0].arn
}

resource "aws_iam_policy" "support" {
    count       = var.disable_iam_support_role ? 0 : 1
    name   = "support"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession",
                "ssm:TerminateSession",
                "ssm:ResumeSession"
            ],
            "Resource": [
                "arn:aws:ec2:*:${local.account_id}:session/$${aws:username}-*",
                "arn:aws:ec2:*:${local.account_id}:instance/${module.main_app[0].instance_id}",
                "arn:aws:ssm:*:${local.account_id}:document/PortForwardingSocks-${var.deployment_id}",
                "arn:aws:ssm:*:${local.account_id}:document/PortForwardingDB-${var.deployment_id}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeSessions",
                "ssm:DescribeInstanceInformation",
                "ssm:GetConnectionStatus",
                "ssm:DescribeInstanceProperties",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeImages",
                "ec2:DescribeAddresses",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes"
            ],
            "Resource": "*"
        },
        {
            "Effect" : "Allow",
            "Action": [
                "autoscaling:Describe*",
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*",
                "cloudwatch:DeleteDashboards",
                "cloudwatch:PutDashboard",
                "cloudwatch:PutMetricData",
                "elasticmapreduce:Describe*",
                "elasticmapreduce:List*",
                "logs:Get*",
                "logs:Describe*",
                "logs:FilterLogEvents",
                "rds:Describe*",
                "sns:Get*",
                "sns:List*",
                "support:*"
            ],
            "Resource": "*"
        },
        {
            "Effect" : "Allow",
            "Action": [
                "dms:Describe*",
                "dms:AddTagsToResource",
                "dms:AssociateExtensionPack",
                "dms:Cancel",
                "dms:CreateEndpoint*",
                "dms:CreateReplicationConfig",
                "dms:CreateReplicationTask",
                "dms:DeleteEndpoint",
                "dms:DeleteReplicationTask",
                "dms:List*",
                "dms:ModifyEndpoint",
                "dms:ModifyInstanceProfile",
                "dms:ModifyReplicationTask",
                "dms:MoveReplicationTask",
                "dms:Refresh*",
                "dms:StartDataMigration",
                "dms:StartReplication",
                "dms:StartReplicationTask",
                "dms:StartReplicationTaskAssessment",
                "dms:StartReplicationTaskAssessmentRun",
                "dms:Stop*",
                "dms:TestConnection",
                "dms:Update*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": ["${aws_kms_key.etleap_encryption_key.arn}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": ["${module.db_support_password.arn}"]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": ["${aws_kms_key.etleap_encryption_key.arn}"],
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:ListAliases"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/etleap/*"
        }
    ]
}
EOF
}
