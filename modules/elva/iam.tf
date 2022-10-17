# User required for reading streaming configurations in streaming-configuration
resource "aws_iam_user" "elva" {
  name = "etleap_streaming_ingress"
}

resource "aws_iam_access_key" "elva" {
  user    = aws_iam_user.elva.name
}


resource "aws_iam_user_policy" "elva" {
  user   = aws_iam_user.elva.name
  name   = "elva"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "*"
    }, 
    {
      "Effect":"Allow",
      "Action":[
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource":[
        "arn:aws:s3:::${var.config_bucket.id}",
        "arn:aws:s3:::${var.config_bucket.id}/*"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
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

resource "aws_iam_instance_profile" "elva" {
  name = "elva"
  role = var.app_role_name
}

resource "aws_iam_policy_attachment" "elva" {
  name       = aws_iam_policy.elva_intermediate_access.name
  roles      = [var.app_role_name]
  policy_arn = aws_iam_policy.elva_intermediate_access.arn
}

resource "aws_iam_policy" "elva_intermediate_access" {
  name = "EtleapElvaIntermediateAccess${var.resource_name_suffix}"

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
      "arn:aws:s3:::${var.config_bucket.id}",
      "arn:aws:s3:::${var.config_bucket.id}/*"
    ]
  }]
}
EOF
}

