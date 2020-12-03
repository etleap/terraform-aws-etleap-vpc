resource "aws_dms_replication_instance" "dms" {
  replication_instance_class   = "dms.t2.micro"
  engine_version               = "3.3.2"
  allocated_storage            = 50
  apply_immediately            = true
  availability_zone            = "us-east-1b"
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  replication_instance_id      = "etleap-dms-${var.deployment_id}-${random_id.deployment_random.hex}"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms.id
  vpc_security_group_ids       = [aws_security_group.dms.id]
  publicly_accessible          = true

  tags = {
    Name = "Etleap DMS"
  }
}

resource "aws_dms_replication_subnet_group" "dms" {
  replication_subnet_group_description = "DMS Subnet Group"
  replication_subnet_group_id          = "etleap-dms-${var.deployment_id}-${random_id.deployment_random.hex}"
  subnet_ids                           = [aws_subnet.a_private.id, aws_subnet.b_private.id]
  tags = {
    Name = "Etleap DMS Subnet Group"
  }
}

resource "aws_security_group" "dms" {
  name        = "Etleap-DMS"
  description = "DMS group"
  vpc_id      = aws_vpc.etleap.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Etleap DMS Security Group"
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
    name               = "dms-vpc-role-${var.deployment_id}-${random_id.deployment_random.hex}"
    assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
    name               = "dms-cloudwatch-logs-role-${var.deployment_id}-${random_id.deployment_random.hex}"
    assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms" {
  name               = "Etleap-dms-role-${var.deployment_id}-${random_id.deployment_random.hex}"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_policy" "dms_s3" {
  name   = "Etleap-DMS-S3-Access-${var.deployment_id}-${random_id.deployment_random.hex}"
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
  name   = "Etleap-Manage-DMS"
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
        "dms:DeleteEndpoint",
        "dms:DescribeTableStatistics"
      ],
      "Resource": "*"
  },
  {
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "${aws_iam_role.dms.arn}"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "dms_s3" {
  role       = aws_iam_role.dms.name
  policy_arn = aws_iam_policy.dms_s3.arn
}

resource "aws_iam_role_policy_attachment" "app_dms" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.job_manage_dms.arn
}
