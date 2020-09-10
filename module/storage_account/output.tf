output "storage_account_id" {
  value = azurerm_storage_account.sql_storage.id
}

output "storage_account_name" {
  value = azurerm_storage_account.sql_storage.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.sql_storage.primary_blob_endpoint
}

output "primary_access_key" {
  value = azurerm_storage_account.sql_storage.primary_access_key
}