resource "aws_cognito_identity_pool" "etleap_azure_identity_pool" {
  count                            = var.disable_cognito_identity_pool ? 0 : 1
  identity_pool_name               = "Etleap - ${var.deployment_id} - Azure Entra ID Federation"
  allow_unauthenticated_identities = false
  developer_provider_name          = "etleap_azure_entra_id"
}

output "cognito_azure_identity_pool" {
  value       = var.disable_cognito_identity_pool ? null : aws_cognito_identity_pool.etleap_azure_identity_pool[0].id
  description = "The ID of the Cognito identity pool for Azure Entra ID federation"
}
