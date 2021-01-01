resource "aws_iam_policy_attachment" "secrets" {
  name       = "Get Deployment Secret"
  roles      = [aws_iam_role.app.name]
  policy_arn = aws_iam_policy.get_secrets.arn
}

resource "aws_iam_policy_attachment" "ec2_describe" {
  name       = "Etleap EC2 Describe"
  roles      = [aws_iam_role.app.name]
  policy_arn = aws_iam_policy.ec2_describe.arn
}

resource "aws_iam_policy_attachment" "cloudwatch_get_metric_data" {
  name       = "Etleap Get Metric Data"
  roles      = [aws_iam_role.app.name]
  policy_arn = aws_iam_policy.cloudwatch_get_metric_data.arn
}

resource "aws_iam_policy_attachment" "assume_any_role" {
  name       = "App and EMR assume any role"
  roles      = [aws_iam_role.app.name, aws_iam_role.emr.name, aws_iam_role.emr_default_role.name]
  policy_arn = aws_iam_policy.assume_any_role.arn
}

resource "aws_iam_role_policy_attachment" "emr_profile_policy" {
  role       = aws_iam_role.emr.name
  policy_arn = aws_iam_policy.emr_profile_policy.arn
}

resource "aws_iam_instance_profile" "emr_profile" {
  name = "EtleapEMRProfile${local.resource_name_suffix}"
  role = aws_iam_role.emr.name
}

resource "aws_iam_role_policy_attachment" "emr_default_role" {
  role       = aws_iam_role.emr_default_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role_policy_attachment" "emr_autoscaling_default_role" {
  role       = aws_iam_role.emr_autoscaling_default_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforAutoScalingRole"
}

resource "aws_iam_role" "emr" {
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

resource "aws_iam_policy" "get_secrets" {
  name   = "EtleapEC2Secrets${local.resource_name_suffix}"
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
                "*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_policy" "ec2_describe" {
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
                "autoscaling:DescribeAutoScalingInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_policy" "cloudwatch_get_metric_data" {
  name   = "EtleapGetMetricData${local.resource_name_suffix}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricData"
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
            "elasticmapreduce:ListInstanceGroups",
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

resource "aws_iam_policy" "assume_any_role" {
  name   = "Etleap_assume_any_role${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role" "emr_default_role" {
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

resource "aws_iam_role" "emr_autoscaling_default_role" {
  name               = "EtleapEMR_AutoScaling_DefaultRole${local.resource_name_suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "elasticmapreduce.amazonaws.com",
          "application-autoscaling.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

