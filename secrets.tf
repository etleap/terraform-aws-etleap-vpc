module "deployment_secret" {
  source  = "app.terraform.io/etleap/password/etleap"
  version = "0.0.2"

  name   = "EtleapDeploymentSecret-${local.resource_name_suffix}"
  length = 40
}

module "db_root_password" {
  source  = "app.terraform.io/etleap/password/etleap"
  version = "0.0.2"

  name   = "EtleapDBRootPassword-${local.resource_name_suffix}"
  length = 20
}

module "admin_password" {
  source  = "app.terraform.io/etleap/password/etleap"
  version = "0.0.2"

  name   = "EtleapAdminPassword-${local.resource_name_suffix}"
  length = 20
}

module "db_password" {
  source  = "app.terraform.io/etleap/password/etleap"
  version = "0.0.2"

  name   = "EtleapDBPassword-${local.resource_name_suffix}"
  length = 20
}

module "db_salesforce_password" {
  source  = "app.terraform.io/etleap/password/etleap"
  version = "0.0.2"

  name   = "EtleapDBSalesforcePassword-${local.resource_name_suffix}"
  length = 20
}

module "setup_password" {
  source  = "app.terraform.io/etleap/password/etleap"
  version = "0.0.2"

  name   = "EtleapSetupPassword-${local.resource_name_suffix}"
  length = 8
}
