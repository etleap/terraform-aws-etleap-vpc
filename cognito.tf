resource "aws_cognito_identity_pool" "etleap_azure_identity_pool" {
  identity_pool_name               = "Etleap - ${var.deployment_id} - Azure Entra ID Federation"
  allow_unauthenticated_identities = false
  developer_provider_name          = "etleap_azure_entra_id"
}

output "cognito_azure_identity_pool" {
  value       = aws_cognito_identity_pool.etleap_azure_identity_pool.id
  description = "The ID of the Cognito identity pool for Azure Entra ID federation"
}
