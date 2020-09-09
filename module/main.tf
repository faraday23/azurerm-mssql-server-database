locals {
    if_threat_detection_policy_enabled = var.enable_threat_detection_policy ? [{}] : []
    if_extended_auditing_policy_enabled = var.enable_auditing_policy ? [{}] : []
}


# Configure the Azure Provider.
provider "azurerm" {
  version = ">=2.2.0"
  features {}
}

# Creates random password for mysql db admin account.
resource "random_password" "db_login_password" {
  length    = 24
  special   = true
}

# Primary ms sql server
resource "azurerm_mssql_server" "primary" {
  name                         = "sql-srvr-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.srvr_version
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.db_login_password.result

  dynamic "extended_auditing_policy" {
        for_each = local.if_extended_auditing_policy_enabled
        content {
            storage_account_access_key = azurerm_storage_account.storeacc.0.primary_access_key
            storage_endpoint           = azurerm_storage_account.storeacc.0.primary_blob_endpoint
            retention_in_days          = var.log_retention_days
        }
    }
}

# SQL servers - Secondary server is depends_on Failover Group
resource "azurerm_mssql_server" "secondary" {
  count                        = var.enable_failover_group ? 1 : 0
  name                         = "sql-srvr-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.srvr_version
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.db_login_password.result

  dynamic "extended_auditing_policy" {
        for_each = local.if_extended_auditing_policy_enabled
        content {
            storage_account_access_key = azurerm_storage_account.storeacc.0.primary_access_key
            storage_endpoint           = azurerm_storage_account.storeacc.0.primary_blob_endpoint
            retention_in_days          = var.log_retention_days
        }
    }
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

  dynamic "threat_detection_policy" {
        for_each = local.if_threat_detection_policy_enabled
        content {
            state                      = "Enabled"
            storage_endpoint           = azurerm_storage_account.storeacc.0.primary_blob_endpoint
            storage_account_access_key = azurerm_storage_account.storeacc.0.primary_access_key
            retention_days             = var.log_retention_days
        }
    }

  dynamic "extended_auditing_policy" {
        for_each = local.if_extended_auditing_policy_enabled
        content {
            storage_account_access_key = azurerm_storage_account.storeacc.0.primary_access_key
            storage_endpoint           = azurerm_storage_account.storeacc.0.primary_blob_endpoint
            retention_in_days          = var.log_retention_days
        }
    }
}



#per_database_settings {
#  geoBackupPolicies         = false
#  securityAlertPolicies     = false
#  transparentDataEncryption = true
#  vulnerabilityAssessments  = false
#}

