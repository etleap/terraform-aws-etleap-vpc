module "deployment_secret" {
  source  = "./modules/password"

  name   = "EtleapDeploymentSecret${local.resource_name_suffix}"
  length = 40
}

module "db_root_password" {
  source  = "./modules/password"

  name   = "EtleapDBRootPassword${local.resource_name_suffix}"
  length = 20
}

module "admin_password" {
  source  = "./modules/password"

  name   = "EtleapAdminPassword${local.resource_name_suffix}"
  length = 20
}

module "db_password" {
  source  = "./modules/password"

  name   = "EtleapDBPassword${local.resource_name_suffix}"
  length = 20
}

module "db_support_password" {
  source  = "./modules/password"

  name   = "EtleapDBSupportPassword${local.resource_name_suffix}"
  length = 20
}

module "db_salesforce_password" {
  source  = "./modules/password"

  name   = "EtleapDBSalesforcePassword${local.resource_name_suffix}"
  length = 20
}

module "setup_password" {
  source  = "./modules/password"

  name   = "EtleapSetupPassword${local.resource_name_suffix}"
  length = 8
}
