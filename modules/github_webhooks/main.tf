# The infrastructure required for consuming Github webhooks, API gateway with domain name that points to an SQS queue

locals {
  queue_prefix = replace(lower(var.deployment_id), ".", "-")
}

# The end SQS queue that will receive the messages
resource "aws_sqs_queue" "github_webhooks_queue" {
  name = "Etleap-${local.queue_prefix}-github-webhooks-queue"
}

# Role and policy for the API gateway to be able to send messages to the SQS queue
resource "aws_iam_role" "github_webhooks_api" {
  name = "Etleap-${var.deployment_id}-GithubWebhooksApi-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "github_webhooks_api" {
  name = "Etleap-${var.deployment_id}-App-SQSGithubWebhooks-Limited-Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sqs:SendMessage"
        ],
        "Resource": "${aws_sqs_queue.github_webhooks_queue.arn}"
      }
    ]
}
EOF
}

# All API Gateway resources
resource "aws_api_gateway_rest_api" "github_webhooks_api" {
  name        = "Etleap-${var.deployment_id}-github_webhooks_api"
  description = "API gateway for Github webhook consumption"
}

resource "aws_iam_role_policy_attachment" "github_webhooks_api" {
  role       = aws_iam_role.github_webhooks_api.name
  policy_arn = aws_iam_policy.github_webhooks_api.arn
}

resource "aws_api_gateway_resource" "github_webhooks_resource" {
  rest_api_id = aws_api_gateway_rest_api.github_webhooks_api.id
  parent_id   = aws_api_gateway_rest_api.github_webhooks_api.root_resource_id
  path_part   = "webhooks"
}

resource "aws_api_gateway_method" "github_webhooks_api" {
  rest_api_id          = aws_api_gateway_rest_api.github_webhooks_api.id
  resource_id          = aws_api_gateway_resource.github_webhooks_resource.id
  api_key_required     = false
  http_method          = "POST"
  authorization        = "NONE"
}

resource "aws_api_gateway_integration" "github_webhooks_api" {
  rest_api_id             = aws_api_gateway_rest_api.github_webhooks_api.id
  resource_id             = aws_api_gateway_resource.github_webhooks_resource.id
  http_method             = "POST"
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  credentials             = aws_iam_role.github_webhooks_api.arn
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${aws_sqs_queue.github_webhooks_queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$util.urlEncode($input.body)"
  }
}

resource "aws_api_gateway_integration_response" "response_200" {
  rest_api_id       = aws_api_gateway_rest_api.github_webhooks_api.id
  resource_id       = aws_api_gateway_resource.github_webhooks_resource.id
  http_method       = aws_api_gateway_method.github_webhooks_api.http_method
  status_code       = aws_api_gateway_method_response.response_200.status_code
  selection_pattern = "^2[0-9][0-9]"

  response_templates = {
    "application/json" = "Success"
  }

  depends_on = [aws_api_gateway_integration.github_webhooks_api]
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.github_webhooks_api.id
  resource_id = aws_api_gateway_resource.github_webhooks_resource.id
  http_method = aws_api_gateway_method.github_webhooks_api.http_method
  status_code = 200
}

resource "aws_api_gateway_deployment" "github_webhooks_api" {
  rest_api_id = aws_api_gateway_rest_api.github_webhooks_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.github_webhooks_api))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "github_webhooks_api" {
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.github_webhooks_api.id
  rest_api_id   = aws_api_gateway_rest_api.github_webhooks_api.id
}

resource "aws_api_gateway_domain_name" "github_domain_name" {
  count                    = var.github_domain_name != null ? 1 : 0
  domain_name              = var.github_domain_name
  security_policy          = "TLS_1_2"
  regional_certificate_arn = var.github_domain_name_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "github_domain_mapping" {
  count       = var.github_domain_name != null ? 1 : 0
  api_id      = aws_api_gateway_rest_api.github_webhooks_api.id
  stage_name  = aws_api_gateway_stage.github_webhooks_api.stage_name
  domain_name = aws_api_gateway_domain_name.github_domain_name[0].domain_name
}

# Limiting access of the API to Github's hook IP ranges
data "github_ip_ranges" "github_ip_ranges" {}

resource "aws_api_gateway_rest_api_policy" "github_hooks_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.github_webhooks_api.id
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = "*"
        Action   = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.github_webhooks_api.id}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp": data.github_ip_ranges.github_ip_ranges.hooks
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "github_webhooks_log_group" {
  name              = "Etleap-${var.deployment_id}-API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.github_webhooks_api.id}/${aws_api_gateway_stage.github_webhooks_api.stage_name}"
  retention_in_days = 90
}