output "resource_group_name" {
  description = "The name of the resource group in which resources are created"  
  value       = var.resource_group_name
}

output "administrator_login" {
  value       = var.administrator_login
  sensitive   = true
  description = "The MySQL instance login for the admin."
}

output "administrator_password" {
  value       = random_password.db_login_password.result
  sensitive   = true
  description = "The MySQL instance password for the admin."
}

output "primary_sql_server_name" {
  value       = azurerm_mssql_server.primary.name
  description = "The Name of the mysql instance."
}

output "primary_sql_server_id" {
  value       = azurerm_mssql_server.primary.id
  description = "The ID of the mysql instance."
}

output "primary_mssql_server_fqdn" {
  description = "The fully qualified domain name of the primary Azure SQL Server" 
  value       = azurerm_mssql_server.primary.fully_qualified_domain_name
}

output "secondary_mssql_server_id" {
  description = "The secondary Microsoft SQL Server ID"
  value       = element(concat(azurerm_mssql_server.secondary.*.id, [""]), 0)
}

output "secondary_mssql_server_fqdn" {
  description = "The fully qualified domain name of the secondary Azure SQL Server" 
  value       = element(concat(azurerm_mssql_server.secondary.*.fully_qualified_domain_name, [""]), 0)
}

output "sql_failover_group_id" {
  description = "A failover group of databases on a collection of Azure SQL servers."
  value       = element(concat(azurerm_sql_failover_group.fog.*.id, [""]), 0)
}
