resource "aws_iam_policy_attachment" "secrets" {
  name       = "Get Deployment Secret"
  roles      = [aws_iam_role.app.name, aws_iam_role.zookeeper.name]
  policy_arn = aws_iam_policy.get_secrets_and_params.arn
}

resource "aws_iam_policy_attachment" "ec2_describe" {
  name       = "Etleap EC2 Describe"
  roles      = [aws_iam_role.app.name]
  policy_arn = aws_iam_policy.ec2_describe.arn
}

resource "aws_iam_policy_attachment" "cloudwatch_metric_data" {
  name       = "Etleap Get and Put Metric Data"
  roles      = [aws_iam_role.app.name, aws_iam_role.zookeeper.name]
  policy_arn = aws_iam_policy.cloudwatch_metric_data.arn
}

resource "aws_iam_policy_attachment" "assume_roles" {
  name       = "App and EMR assume any role"
  roles      = [aws_iam_role.app.name, aws_iam_role.emr.name, aws_iam_role.emr_default_role.name]
  policy_arn = aws_iam_policy.assume_roles.arn
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

resource "aws_iam_role_policy_attachment" "allow_sns_put" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.allow_sns_put.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_crud" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.dynamodb_crud.arn
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

resource "aws_iam_policy" "ec2_describe" {
  tags   = local.default_tags
  name   = "EtleapEC2Describe${local.resource_name_suffix}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "autoscaling:DescribeAutoScalingInstances",
                "elasticmapreduce:ListInstanceFleets",
                "elasticmapreduce:ModifyInstanceFleet"
            ],
            "Resource": [
                "*"
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

resource "aws_iam_policy" "assume_roles" {
  tags   = local.default_tags
  name   = "Etleap_assume_roles${local.resource_name_suffix}"
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

resource "aws_iam_policy" "allow_sns_put" {
  tags   = local.default_tags
  name   = "Etleap_sns_put${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "SnsAllowOutboundMessages",
  "Statement": [{
    "Sid": "SnsAllowPublishToAny",
    "Effect": "Allow",
    "Action": "sns:Publish",
    "Resource": "*"
  }]
}
EOF
}

resource aws_iam_policy "dynamodb_crud" {
  tags   = local.default_tags
  name   = "Etleap-dynamodb-crud${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
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