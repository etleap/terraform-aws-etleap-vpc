module "deployment_secret" {
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "EtleapDeploymentSecret${local.resource_name_suffix}"
  length = 40
}

module "db_root_password" {
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "EtleapDBRootPassword${local.resource_name_suffix}"
  length = 20
}

module "admin_password" {
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "EtleapAdminPassword${local.resource_name_suffix}"
  length = 20
}

module "db_password" {
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "EtleapDBPassword${local.resource_name_suffix}"
  length = 20
}

module "db_support_password" {
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "Etleap-${var.deployment_id}-DBSupportPassword"
  length = 20
}

module "setup_password" {
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "EtleapSetupPassword${local.resource_name_suffix}"
  length = 8
}
