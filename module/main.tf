locals {
    if_threat_detection_policy_enabled  = var.enable_threat_detection_policy ? [{}] : []
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
            storage_account_access_key = var.storage_account_access_key 
            storage_endpoint           = var.storage_endpoint
            retention_in_days          = var.log_retention_days
        }
    }
  tags = var.tags
}

# SQL servers - Secondary server is depends_on Failover Group
resource "azurerm_mssql_server" "secondary" {
  count                         = var.enable_failover_group ? 1 : 0
  name                          = "sql-srvr-failover${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name           = var.resource_group_name
  location                      = var.secondary_sql_server_location
  version                       = var.srvr_version
  administrator_login           = var.administrator_login
  administrator_login_password  = random_password.db_login_password.result

  dynamic "extended_auditing_policy" {
        for_each = local.if_extended_auditing_policy_enabled
        content {
            storage_endpoint           = var.storage_endpoint
            storage_account_access_key = var.storage_account_access_key 
            retention_in_days          = var.log_retention_days
        }
    }
}

# Manages a Microsoft SQL Azure Database.
resource "azurerm_mssql_database" "db" {
  name                  = "sql-db-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  server_id             = azurerm_mssql_server.primary.id
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
            storage_endpoint           = var.storage_endpoint
            storage_account_access_key = var.storage_account_access_key 
            retention_days             = var.log_retention_days
        }
    }

  dynamic "extended_auditing_policy" {
        for_each = local.if_extended_auditing_policy_enabled
        content {
            storage_endpoint           = var.storage_endpoint
            storage_account_access_key = var.storage_account_access_key 
            retention_in_days          = var.log_retention_days
        }
    }

  tags = var.tags
}

#per_database_settings {
#  geoBackupPolicies         = false
#  securityAlertPolicies     = false
#  transparentDataEncryptionName = enabled
#  vulnerabilityAssessments  = false
#}


# Adding AD Admin to SQL Server - Secondary server depend on Failover Group - Default is "false"
data "azurerm_client_config" "current" {}

resource "azurerm_sql_active_directory_administrator" "aduser1" {
    count                   = var.enable_sql_ad_admin ? 1 : 0
    server_name             = azurerm_mssql_server.primary.name
    resource_group_name     = var.resource_group_name
    login                   = var.ad_admin_login_name
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azurerm_client_config.current.object_id
}

resource "azurerm_sql_active_directory_administrator" "aduser2" {
    count                   = var.enable_failover_group && var.enable_sql_ad_admin ? 1 : 0
    server_name             = azurerm_mssql_server.secondary.0.name
    resource_group_name     = var.resource_group_name
    login                   = var.ad_admin_login_name
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azurerm_client_config.current.object_id
}

# Azure SQL Failover Group - Default is "false" 
resource "azurerm_sql_failover_group" "fog" {
  count               = var.enable_failover_group ? 1 : 0
  name                = "sqldb-failover-group"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.primary.name
  databases           = [azurerm_mssql_database.db.id]
  tags                = var.tags
  partner_servers {
      id = azurerm_mssql_server.secondary.0.id
    }

  read_write_endpoint_failover_policy {
      mode           = "Automatic"
      grace_minutes  = 60
    }

  readonly_endpoint_failover_policy {
      mode           = "Enabled"
    }
}

# Azure SQL Firewall Rule - Default is "false"
resource "azurerm_sql_firewall_rule" "fw01" {
    count                = var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
    name                 = element(var.firewall_rules, count.index).name
    resource_group_name  = var.resource_group_name
    server_name          = azurerm_mssql_server.primary.name
    start_ip_address     = element(var.firewall_rules, count.index).start_ip_address
    end_ip_address       = element(var.firewall_rules, count.index).end_ip_address
}

resource "azurerm_sql_firewall_rule" "fw02" {
    count                = var.enable_failover_group && var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
    name                 = element(var.firewall_rules, count.index).name
    resource_group_name  = var.resource_group_name
    server_name          = azurerm_mssql_server.secondary.0.name
    start_ip_address     = element(var.firewall_rules, count.index).start_ip_address
    end_ip_address       = element(var.firewall_rules, count.index).end_ip_address
}
