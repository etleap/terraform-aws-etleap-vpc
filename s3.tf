resource "aws_s3_bucket" "log" {
  bucket        = "etleap-logs-${var.deployment_id}-${random_id.deployment_random.hex}"
  force_destroy = true
}

resource "aws_s3_bucket" "intermediate" {
  bucket        = "etleap-intermediate-${var.deployment_id}-${random_id.deployment_random.hex}"
  force_destroy = true
}

resource "aws_iam_role" "intermediate" {
  name               = "EtleapIntermediate-${var.deployment_id}-${random_id.deployment_random.hex}"
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

resource "aws_iam_policy" "intermediate" {
  name = "EtleapIntermediate-${var.deployment_id}-${random_id.deployment_random.hex}"

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
