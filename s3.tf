resource "aws_s3_bucket" "intermediate" {
  bucket        = "etleap-intermediate-${var.deployment_id}-${random_id.deployment_random.hex}"
  force_destroy = true

  lifecycle_rule {
    id      = "emr-logs"
    enabled = true
    prefix  = "emr-logs/"

    expiration {
      days = 90
    }
  }

  lifecycle {
    ignore_changes = [
      bucket,
      logging
    ]
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.s3_kms_encryption_key
        sse_algorithm     = var.s3_kms_encryption_key == null ? "AES256" : "aws:kms"
      }
    }
  }
}

resource "aws_iam_role" "intermediate" {
  name               = "EtleapIntermediate${local.resource_name_suffix}"
  max_session_duration = 14400
  lifecycle {
    ignore_changes = [max_session_duration]
  }
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.app.name}",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.emr.name}"
        ]
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": { "sts:ExternalId": "${var.deployment_id}" }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "intermediate" {
  name = "EtleapIntermediate${local.resource_name_suffix}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[{
    "Effect":"Allow",
    "Action":[
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ],
    "Resource":[
      "arn:aws:s3:::${aws_s3_bucket.intermediate.id}",
      "arn:aws:s3:::${aws_s3_bucket.intermediate.id}/*"
    ]
  }]
}
EOF
}

resource "aws_iam_policy_attachment" "intermediate" {
  name       = "Intermediate Bucket Access"
  roles      = [aws_iam_role.intermediate.name]
  policy_arn = aws_iam_policy.intermediate.arn
}

resource "random_id" "deployment_random" {
  byte_length = 3
}

resource "aws_iam_role" "s3_input_role" {
  count              = length(var.s3_input_buckets) > 0 ? 1 : 0
  name               = "EtleapInput${local.resource_name_suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": { "sts:ExternalId": "${var.deployment_id}" }
      }
    }
  ]
}
EOF
}

resource aws_iam_policy "s3_input_policy" {
  count  = length(var.s3_input_buckets) > 0 ? 1 : 0
  name   = "EtleapInput${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[{
    "Effect":"Allow",
    "Action":[
      "s3:GetObject",
      "s3:ListBucket"
    ],
    "Resource": [
      ${join(",\n", formatlist("\"arn:aws:s3:::%s\"", var.s3_input_buckets))},
      ${join(",\n", formatlist("\"arn:aws:s3:::%s/*\"", var.s3_input_buckets))}
    ]
  },
  {
    "Effect":"Allow",
    "Action": [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ],
    "Resource":[
      "${aws_s3_bucket.intermediate.arn}",
      "${aws_s3_bucket.intermediate.arn}/*"
    ]
  }]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_input" {
  count      = length(var.s3_input_buckets) > 0 ? 1 : 0
  name       = "Input Bucket Access"
  roles      = [aws_iam_role.s3_input_role[0].name]
  policy_arn = aws_iam_policy.s3_input_policy[0].arn
}

resource "aws_s3_bucket_policy" "intermediate" {
  bucket = aws_s3_bucket.intermediate.id
  policy = templatefile("${path.module}/templates/intermediate-bucket-policy.tpl", {
    s3_data_lake_account_ids = var.s3_data_lake_account_ids,
    intermediate_bucket_name = aws_s3_bucket.intermediate.id,
    intermediate_bucket_arn  = aws_s3_bucket.intermediate.arn
  })
}
