variable "db_id" {
  description = "identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
}

variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}

# Configure Providers
provider "azurerm" {
  version = ">=2.2.0"
  subscription_id = "00000000-0000-0000-0000-00000000"
  features {}
}

##
# Pre-Built Modules 
##

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = "b0837458-adf3-41b0-a8fb-c16f9719627d"
}

module "rules" {
  source = "git@github.com:[redacted]/python-azure-naming.git?ref=tf"
}

# For tags and info see https://github.com/Azure-Terraform/terraform-azurerm-metadata 
# For naming convention see https://github.com/[redacted]/python-azure-naming 
module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.1.0"

  naming_rules = module.rules.yaml
  
  market              = "us"
  location            = "useast1"
  sre_team            = "alpha"
  environment         = "sandbox"
  project             = "mssql"
  business_unit       = "iog"
  product_group       = "tfe"
  product_name        = "mssqlsrvr"
  subscription_id     = "0000000-0000-0000-0000-0000000"
  subscription_type   = "nonprod"
  resource_group_type = "app"
}

module "resource_group" {
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v1.0.0"
  
  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

# mysql-server storage account
module "storage_acct" {
  source = "../ms_sql_module/storage_account"
  # Required inputs 
  db_id               = var.db_id
  # Pre-Built Modules  
  location            = module.metadata.location
  names               = module.metadata.names
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name
}

# SQL server advanced threat protection 
module "atp" {
  source = "../ms_sql_module/advanced_threat_protection"
  # Required inputs 
  storage_account_id  = module.storage_acct.storage_account_id
}

# mysql-server module
module "mssql_server" {
  source = "../ms_sql_module/ms_sql_server"
  # Required inputs 
  db_id                          = var.db_id
  subscription_name              = "infrastructure-sandbox"
  # SQL server and database audit policies and advanced threat protection 
  enable_auditing_policy         = true
  enable_threat_detection_policy = true
  # SQL failover group
  enable_failover_group          = true
  secondary_sql_server_location  = "westus"
  # Azure AD administrator for azure sql server
  enable_sql_ad_admin            = true
  ad_admin_login_name            = "first.last@contoso.com"
  log_retention_days             = 7
  # Storage endpoints for audit logs and atp logs
  storage_endpoint               = module.storage_acct.primary_blob_endpoint
  storage_account_access_key     = module.storage_acct.primary_access_key   
  # SQL server firewall naming rules
  enable_firewall_rules          = true
  
  # Pre-Built Modules  
  location            = module.metadata.location
  names               = module.metadata.names
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name
}
