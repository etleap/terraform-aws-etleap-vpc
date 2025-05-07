output "github_webhooks_queue" {
  value = aws_sqs_queue.github_webhooks_queue
  description = "The SQS queue that receives GitHub webhook events."
}

output "github_webhooks_url" {
  value = var.github_domain_name == null ? "${aws_api_gateway_stage.github_webhooks_api.invoke_url}/webhooks" : "https://${var.github_domain_name}/webhooks"
}

output "github_webhooks_regional_domain_name" {
  value = var.github_domain_name != null ? aws_api_gateway_domain_name.github_domain_name[0].regional_domain_name : null
}
