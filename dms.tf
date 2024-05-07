resource "aws_dms_replication_instance" "dms" {
  count                        = var.disable_cdc_support ? 0 : 1
  tags                         = merge({Name = "Etleap DMS ${var.deployment_id}"}, local.default_tags)
  replication_instance_class   = var.dms_instance_type
  engine_version               = "3.5.1"
  allocated_storage            = 50
  apply_immediately            = true
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  replication_instance_id      = "etleap-dms${local.resource_name_suffix}"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms[0].id
  vpc_security_group_ids       = [aws_security_group.dms[0].id]
  publicly_accessible          = true
}

resource "aws_dms_replication_instance" "dms_downgraded" {
  count                        = (!var.disable_cdc_support && var.downgrade_cdc) ? 1 : 0
  tags                         = merge({Name = "Etleap DMS Downgraded ${var.deployment_id}"}, local.default_tags)
  replication_instance_class   = var.dms_instance_type
  engine_version               = "3.4.6"
  allocated_storage            = 50
  apply_immediately            = true
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  replication_instance_id      = "etleap-dms-downgraded${local.resource_name_suffix}"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms[0].id
  vpc_security_group_ids       = [aws_security_group.dms[0].id]
  publicly_accessible          = true
}

resource "aws_dms_replication_subnet_group" "dms" {
  count                                = var.disable_cdc_support ? 0 : 1
  tags                                 = merge({Name = "Etleap DMS Subnet Group"}, local.default_tags)
  replication_subnet_group_description = "DMS Subnet Group"
  replication_subnet_group_id          = "etleap-dms${local.resource_name_suffix}"
  subnet_ids                           = [local.subnet_a_private_id, local.subnet_b_private_id]
}

resource "aws_security_group" "dms" {
  count       = var.disable_cdc_support ? 0 : 1
  tags        = merge({Name = "Etleap DMS Security Group"}, local.default_tags)
  name        = "Etleap-DMS"
  description = "DMS group"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    sid = "1"

    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "dms-vpc-role" {
    count              = var.dms_roles_to_be_created && !var.disable_cdc_support ? 1 : 0
    tags               = local.default_tags
    name               = "dms-vpc-role"
    assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  count      = var.dms_roles_to_be_created && !var.disable_cdc_support ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role[0].name
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
    count              = var.dms_roles_to_be_created && !var.disable_cdc_support ? 1 : 0
    tags               = local.default_tags
    name               = "dms-cloudwatch-logs-role"
    assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  count      = var.dms_roles_to_be_created && !var.disable_cdc_support? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role[0].name
}

resource "aws_iam_role" "dms" {
  count              = var.disable_cdc_support ? 0 : 1
  tags               = local.default_tags
  name               = "Etleap-dms-role${local.resource_name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_policy" "dms_s3" {
  count  = var.disable_cdc_support ? 0 : 1
  tags   = local.default_tags
  name   = "Etleap-DMS-S3-Access${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject",
        "s3:PutObjectTagging",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.intermediate.id}",
        "arn:aws:s3:::${aws_s3_bucket.intermediate.id}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "job_manage_dms" {
  count  = var.disable_cdc_support ? 0 : 1
  tags   = local.default_tags
  name   = "Etleap-Manage-DMS${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dms:DescribeReplicationTasks",
        "dms:CreateReplicationTask",
        "dms:ModifyReplicationTask",
        "dms:DeleteReplicationTask",
        "dms:StartReplicationTask",
        "dms:StopReplicationTask",
        "dms:DescribeEndpoints",
        "dms:CreateEndpoint",
        "dms:ModifyEndpoint",
        "dms:DeleteEndpoint",
        "dms:DescribeTableStatistics",
        "dms:TestConnection",
        "dms:DescribeConnections"
      ],
      "Resource": "*"
  },
  {
    "Effect": "Allow",
      "Action": "logs:FilterLogEvents",
      "Resource": "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:dms-tasks-${aws_dms_replication_instance.dms[0].replication_instance_id}:*"
  },
  {
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "${aws_iam_role.dms[0].arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dms_s3" {
  count      = var.disable_cdc_support ? 0 : 1
  role       = aws_iam_role.dms[0].name
  policy_arn = aws_iam_policy.dms_s3[0].arn
}

resource "aws_iam_role_policy_attachment" "app_dms" {
  count      = var.disable_cdc_support ? 0 : 1
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.job_manage_dms[0].arn
}
