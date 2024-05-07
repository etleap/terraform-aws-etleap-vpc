variable "organization" {
}

variable "tags" {
  type = map(string)
  default = {}
}

resource "aws_sns_topic" "etleap-inbound" {
  tags = var.tags
  name = "etleap-inbound-${var.organization}"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.etleap-inbound.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.etleap-inbound.arn
  raw_message_delivery = true
}

resource "aws_sqs_queue" "etleap-inbound-dlq" {
  tags = var.tags
  name = "etleap-inbound-dlq-${var.organization}"
}

resource "aws_sqs_queue" "etleap-inbound" {
  tags           = var.tags
  name           = "etleap-inbound-${var.organization}"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.etleap-inbound-dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_policy" "allow-sns-write" {
  queue_url = aws_sqs_queue.etleap-inbound.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "${aws_sqs_queue.etleap-inbound.arn}/SQSDefaultPolicy",
  "Statement": [{
    "Sid": "topic-subscription-arn:${aws_sns_topic_subscription.user_updates_sqs_target.arn}",
    "Effect": "Allow",
    "Principal": {
      "AWS": "*"
    },
    "Action": "SQS:SendMessage",
    "Resource": "${aws_sqs_queue.etleap-inbound.arn}",
    "Condition": {
      "ArnLike": {
        "aws:SourceArn": "${aws_sns_topic.etleap-inbound.arn}"
      }
    }
  }]
}
EOF
}

resource "aws_sqs_queue_policy" "allow-sqs-write-dlq" {
  queue_url = aws_sqs_queue.etleap-inbound-dlq.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "${aws_sqs_queue.etleap-inbound-dlq.arn}/SQSDLQDefaultPolicy",
  "Statement": [{
    "Sid": "main-sqs-arn:${aws_sqs_queue.etleap-inbound.arn}",
    "Effect": "Allow",
    "Principal": {
      "AWS": "*"
    },
    "Action": "SQS:SendMessage",
    "Resource": "${aws_sqs_queue.etleap-inbound-dlq.arn}",
    "Condition": {
      "ArnLike": {
        "aws:SourceArn": "${aws_sqs_queue.etleap-inbound.arn}"
      }
    }
  }]
}
EOF
}

output "sns_topic_arn" {
  value = aws_sns_topic.etleap-inbound.arn
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.etleap-inbound.arn
}
