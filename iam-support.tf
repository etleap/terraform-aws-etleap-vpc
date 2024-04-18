resource "aws_iam_role" "support" {
    count       = var.allow_iam_support_role ? 1 : 0
    name        = "Etleap-${var.deployment_id}-Support-Role"
    description = "Role for Etleap's support team."
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

resource "aws_iam_role_policy_attachment" "support_ssm_limited" {
    count       = var.allow_iam_support_role && var.app_available ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_ssm_limited[0].arn
}

resource "aws_iam_role_policy_attachment" "support_logs_dms_limited" {
    count       = var.allow_iam_support_role && ! var.disable_cdc_support ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_logs_dms_limited[0].arn
}

resource "aws_iam_role_policy_attachment" "support_ec2_read" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_ec2_read[0].arn
}

resource "aws_iam_role_policy_attachment" "support_autoscaling_emr_rds_sns_read" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_autoscaling_emr_rds_sns_read[0].arn
}

resource "aws_iam_role_policy_attachment" "support_support_full" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_support_full[0].arn
}

resource "aws_iam_role_policy_attachment" "support_sns_read" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_sns_read[0].arn
}

resource "aws_iam_role_policy_attachment" "support_cloudwatch_read" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_cloudwatch_read[0].arn
}

resource "aws_iam_role_policy_attachment" "support_secretsmanager_limited" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_secretsmanager_limited[0].arn
}

resource "aws_iam_role_policy_attachment" "support_ssm_read_limited" {
    count       = var.allow_iam_support_role ? 1 : 0
    role        = aws_iam_role.support[0].name
    policy_arn  = aws_iam_policy.support_ssm_read[0].arn
}

resource "aws_iam_policy" "support_ssm_limited" {
    count  = var.allow_iam_support_role && var.app_available ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-SSM-Limited-Policy"
    description = "Start, stop, and resume Port Forwarding to the DB (RDS) instance and SOCKS proxy (using SSM sessions) specifically using the deployment's app instance."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession",
                "ssm:TerminateSession",
                "ssm:ResumeSession",
                "ssm:DescribeSessions",
                "ssm:DescribeInstanceInformation",
                "ssm:GetConnectionStatus",
                "ssm:DescribeInstanceProperties"
            ],
            "Resource": [
                "arn:aws:ec2:*:${local.account_id}:session/$${aws:username}-*",
                "arn:aws:ec2:*:${local.account_id}:instance/${module.main_app[0].instance_id}",
                "arn:aws:ssm:*:${local.account_id}:document/PortForwardingSocks-${var.deployment_id}",
                "arn:aws:ssm:*:${local.account_id}:document/PortForwardingDB-${var.deployment_id}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_logs_dms_limited" {
    count  = var.allow_iam_support_role && ! var.disable_cdc_support ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-Logs_DMS-Limited-Policy"
    description = "DMS-related resource access, only if CDC support is enabled for the deployment. Includes read of the deployment's DMS replication instance's CloudWatch log group, list resources related to DMS, and full CRUD of the deployment's DMS resources, including endpoints, replication tasks, and assessments."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect" : "Allow",
            "Action": [
                "logs:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect" : "Allow",
            "Action": [
                "logs:Get*",
                "logs:FilterLogEvents",
                "logs:ListTagsForResource"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:dms-tasks-${aws_dms_replication_instance.dms[0].replication_instance_id}:*"
            ]
        },
        {
            "Effect" : "Allow",
            "Action": [
                "dms:Describe*",
                "dms:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect" : "Allow",
            "Action": [
                "dms:AddTagsToResource",
                "dms:AssociateExtensionPack",
                "dms:Cancel",
                "dms:CreateReplicationConfig",
                "dms:CreateReplicationTask",
                "dms:ModifyInstanceProfile",
                "dms:Refresh*",
                "dms:StartDataMigration",
                "dms:Stop*",
                "dms:Update*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {"aws:ResourceTag/Deployment": "${var.deployment_id}"}
            }
        },
        {
            "Effect" : "Allow",
            "Action": [
                "dms:Describe*",
                "dms:StartReplicationTask",
                "dms:ModifyReplicationTask",
                "dms:StopReplicationTask",
                "dms:MoveReplicationTask",
                "dms:DeleteReplicationTask",
                "dms:StartReplication",
                "dms:StartReplicationTaskAssessment",
                "dms:StartReplicationTaskAssessmentRun",
                "dms:StopReplication",
                "dms:CreateEndpoint*",
                "dms:ModifyEndpoint",
                "dms:DeleteEndpoint",
                "dms:TestConnection"
            ],
            "Resource": [
                "arn:aws:dms:${var.region}:${data.aws_caller_identity.current.account_id}:task:*",
                "arn:aws:dms:${var.region}:${data.aws_caller_identity.current.account_id}:endpoint:*"
            ]
        },
        {
            "Effect" : "Allow",
            "Action": [
                "dms:TestConnection"
            ],
            "Resource": [
                "arn:aws:dms:${var.region}:${data.aws_caller_identity.current.account_id}:rep:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_ec2_read" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-EC2-Read-Policy"
    description = "Describe EC2 instances, network interfaces, images, addresses, subnets, tags, and volumes."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeImages",
                "ec2:DescribeAddresses",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_autoscaling_emr_rds_sns_read" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-Autoscaling_EMR_RDS_SNS-Read-Policy"
    description = "List resources related to Auto Scaling, EMR, RDS, and SNS."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect" : "Allow",
            "Action": [
                "autoscaling:Describe*",
                "elasticmapreduce:Describe*",
                "elasticmapreduce:List*",
                "rds:Describe*",
                "sns:List*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_support_full" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-Support-Full-Policy"
    description = "Full access to AWS Support."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect" : "Allow",
            "Action": [
                "support:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_sns_read" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-SNS-Read-Policy"
    description = "List SNS topics and queues related to the deployment."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect" : "Allow",
            "Action": [
                "sns:Get*"
            ],
            "Resource": [
                "${module.inbound_queue.sns_topic_arn}",
                "${module.inbound_queue.sqs_queue_arn}"
            ],
            "Condition": {
                "StringEquals": {"aws:ResourceTag/Deployment": "${var.deployment_id}"}
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_cloudwatch_read" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-Cloudwatch-Read-Policy"
    description = "List and read metric data from CloudWatch."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect" : "Allow",
            "Action": [
                "cloudwatch:List*",
                "cloudwatch:Describe*",
                "cloudwatch:GetMetricData"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_secretsmanager_limited" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-Secretsmanager-Limited-Policy"
    description = "Read the deployment's database's support user's password from Secrets Manager."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": ["${module.db_support_password.arn}"]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "support_ssm_read" {
    count  = var.allow_iam_support_role ? 1 : 0
    name   = "Etleap-${var.deployment_id}-Support-SSM-Read-Policy"
    description = "Read the deployment's Parameter Store parameters."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:${var.region}:${local.account_id}:parameter/etleap/${var.deployment_id}/*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "support_emr_read" {
  count      = var.allow_iam_support_role ? 1 : 0
  role       = aws_iam_role.support[0].name
  policy_arn = aws_iam_policy.support_s3_read[0].arn
}

resource "aws_iam_policy" "support_s3_read" {
  count  = var.allow_iam_support_role ? 1 : 0
  name   = "Etleap-${var.deployment_id}-Support-S3-EMR-Read-Policy"
  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListingOfEMRLogs",
            "Action": "s3:ListBucket",
            "Effect": "Allow",
            "Resource": "${aws_s3_bucket.intermediate.arn}",
            "Condition": {"StringLike": {"s3:prefix": ["emr-logs/*"]}}
        },
        {
            "Sid": "AllowReadEMRLogs",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "${aws_s3_bucket.intermediate.arn}/emr-logs/*"
        }
  ]
}
EOF
}
