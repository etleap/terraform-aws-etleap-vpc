module "inbound_queue" {
  source       = "./modules/event-queue"
  organization = var.deployment_id
}

resource "aws_iam_policy" "inbound-sns-sqs-manage" {
  name   = "Etleap-inbound-sns-sqs-manage${local.resource_name_suffix}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "SqsAllowManagement",
  "Statement": [
  {
    "Sid":"SqsAllowAll",
    "Effect": "Allow",
    "Action": "sqs:*",
    "Resource": "${module.inbound_queue.sqs_queue_arn}"
  },
  {
    "Sid":"SnsAllowAll",
    "Effect": "Allow",
    "Action": "sns:*",
    "Resource": "${module.inbound_queue.sns_topic_arn}"
  }
]
}
EOF
}

resource "aws_iam_policy_attachment" "allow-sqs-app" {
  name = "allow-sqs-app"
  roles = [aws_iam_role.app.name]
  policy_arn = aws_iam_policy.inbound-sns-sqs-manage.arn
}
