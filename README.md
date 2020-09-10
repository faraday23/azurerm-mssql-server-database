# Azure Database for MS SQL Server

This repo contains an example Terraform configuration that deploys a MySQL database using Azure.
For more info, please see https://docs.microsoft.com/en-us/azure/azure-sql/database/.

## Version compatibility

| Module version    | Terraform version | AzureRM version |
|-------------------|-------------------|-----------------|
| >= 1.x.x          | 0.13.x            | >= 2.2.0        |



## Example Usage

```hcl
variable "db_id" {
  description = "Identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
}

variable "names" {
  description = "Names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "Tags to be applied to resources"
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
  subscription_id = "00000000-0000-0000-0000-00000000"
}

module "rules" {
  source = "git@github.com:openrba/python-azure-naming.git?ref=tf"
}

# For tags and info see https://github.com/Azure-Terraform/terraform-azurerm-metadata 
# For naming convention see https://github.com/openrba/python-azure-naming 
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
  subscription_id     = "00000000-0000-0000-0000-00000000"
  subscription_type   = "nonprod"
  resource_group_type = "app"
}

##
# Resources 
##

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

# mysql-server module
module "mssql_server" {
  source = "../ms_sql_module/ms_sql_server"
  # Required inputs 
  db_id                          = var.db_id
  enable_failover_group          = false
  subscription_name              = "infrastructure-sandbox"
  enable_auditing_policy         = true
  enable_threat_detection_policy = true
  log_retention_days             = 7
  storage_endpoint               = module.storage_acct.primary_blob_endpoint
  storage_account_access_key     = module.storage_acct.primary_access_key   

  # Pre-Built Modules  
  location            = module.metadata.location
  names               = module.metadata.names
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name
}
```
## Required Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| subscription_name | Name of Azure Subscription | `string` | n/a | 
| resource_group_name | Resource group name | `string` | n/a | 
| tags | tags to be applied to resources | `string` | n/a |
| names | names to be applied to resources | `string` | n/a | 
| db_id | Identifier appended to db name (productname-environment-mysql<db_id>) | `string` | n/a |
| location | Location for all resources| `string` | `"eastus"` | 
| sku_name | Specifies the name of the sku used by the database. For example, GP_S_Gen5_2,HS_Gen4_1,BC_Gen5_2, ElasticPool, Basic,S0 | `string` | `"GP_Gen5_2"` | 
| max_size_gb | The max size of the database in gigabytes. | `string` | `"10"` | 
| srvr_version | The version for the new server. Valid values are: 12.0 (for v12 server). | `string` | `"12.0"` | 
| enable_auditing_policy | Audit policy for SQL server and database. | `bool` | `"false"` | 
| enable_threat_detection_policy | Threat detection policy configuration, known in the API as Server Security Alerts Policy. | `bool` | `"false"` | 
| enable_failover_group | Create a failover group of databases on a collection of Azure SQL servers | `bool` | `"false"` | 
| enable_firewall_rules | Manage an Azure SQL Firewall Rule | `bool` | `"false"` | 
| secondary_sql_server_location | Specifies the supported Azure location to create secondary sql server resource | `string` | `"westus"` | 
| log_retention_days | Specifies the number of days to keep in the Threat Detection audit logs | `string` | `"7"` | 
| storage_endpoint | This blob storage will hold all Threat Detection audit logs. Required if state is Enabled. | `string` | n/a | 
| storage_account_access_key | Specifies the identifier key of the Threat Detection audit storage account. Required if state is Enabled. | `string` | n/a | 


## Quick start

1.Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).\
2.Sign into your [Azure Account](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest)


```
# Login with the Azure CLI/bash terminal/powershell by running
az login

# Verify access by running
az account show --output jsonc

# Confirm you are running required/pinned version of terraform
terraform version
```

Deploy the code:

```
terraform init
terraform plan -out azure-mysql-01.tfplan
terraform apply azure-mysql-01.tfplan
```



