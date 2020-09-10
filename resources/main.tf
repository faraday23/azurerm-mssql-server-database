# Configure the Azure Provider.
provider "azurerm" {
  version = ">=2.0.0"
  features {}
}

# Configure name of storage account
resource "random_string" "storage_name" {
    length  = 8
    upper   = false
    lower   = true
    number  = true
    special = false
}

# Creates random password for mysql db admin account.
resource "random_password" "db_login_password" {
  length    = 24
  special   = true
}

# Manages an Azure Storage Account.
resource "azurerm_storage_account" "sql_storage" {
  name                     = "st${random_string.storage_name.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# Manages a Microsoft SQL Azure Database Server.
resource "azurerm_mssql_server" "server" {
  name                         = "sql-srvr-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.srvr_version
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.db_login_password.result

  tags = var.tags
}

# Manages a Microsoft SQL Azure Database.
resource "azurerm_mssql_database" "db" {
  name                  = "sql-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  server_id             = azurerm_mssql_server.server.id
  collation             = var.collation
  license_type          = var.license_type
  sku_name              = var.sku_name
  max_size_gb           = var.max_size_gb
  zone_redundant        = var.zone_redundant
  read_scale            = var.read_scale
  read_replica_count    = var.read_replica_count

  threat_detection_policy {
    enabled                     = true                 
    storage_endpoint            = azurerm_storage_account.sql_storage.primary_blob_endpoint
    storage_account_access_key  = azurerm_storage_account.sql_storage.primary_access_key
    retention_days              = 7
  }

  #per_database_settings {
  #  geoBackupPolicies         = false
  #  securityAlertPolicies     = false
  #  transparentDataEncryption = true
  #  vulnerabilityAssessments  = false
  #}

  tags = var.tags
}
