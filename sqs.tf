module "inbound_queue" {
  source       = "./modules/event-queue"
  tags         = local.default_tags
  organization = var.deployment_id
}

# The permissions for the inbound queue are part of the app_various_limited
# policy, to avoid breaching the 10 policy per role limit.
