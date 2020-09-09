output "administrator_login" {
  value       = var.administrator_login
  sensitive   = true
  description = "The MySQL instance login for the admin."
}

output "password" {
  value       = random_password.db_login_password.result
  sensitive   = true
  description = "The MySQL instance password for the admin."
}

output "name" {
  value       = azurerm_mssql_server.server.name
  description = "The Name of the mysql instance."
}

output "id" {
  value       = azurerm_mssql_server.server.id
  description = "The ID of the mysql instance."
}
