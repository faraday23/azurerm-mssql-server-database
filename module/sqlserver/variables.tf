##
# Required parameters
##

variable "subscription_name" {
    type        = string
    description = "Name of Azure Subscription"
}

variable "resource_group_name"{
  description = "Resource group name"
  type        = string
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}

variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "db_id" {
  description = "Identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
}

variable "location" {
    type        = string
    description = "Location for all resources"
}

variable "sku_name" {
    type        = string
    description = "Specifies the name of the sku used by the database. Only changing this from tier Hyperscale to another tier will force a new resource to be created. For example, GP_S_Gen5_2,HS_Gen4_1,BC_Gen5_2, ElasticPool, Basic,S0, P2 ,DW100c, DS100."
    default     = "GP_Gen5_2"
}

variable "max_size_gb" {
    type        = number
    description = "The max size of the database in gigabytes."
    default     = "10"
}

variable "srvr_version" {
    type        = string
    description = "The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server)."
    default     = "12.0"
}

variable "enable_auditing_policy" {
    description = "Audit policy for SQL server and database."
    default     = false
}

variable "enable_threat_detection_policy" {
    description = "Threat detection policy configuration, known in the API as Server Security Alerts Policy."
    type        = bool
    default     = false 
}

variable "enable_failover_group" {
    description = "Create a failover group of databases on a collection of Azure SQL servers"
    type        = bool
    default     = false
}

variable "secondary_sql_server_location" {
    description = "Specifies the supported Azure location to create secondary sql server resource"
    default     = "westus" 
}

variable "log_retention_days" {
    description = "Specifies the number of days to keep in the Threat Detection audit logs"
    default     = "7"
}

variable "enable_firewall_rules" {
    description = "Manage an Azure SQL Firewall Rule"
    default     = false
}

variable "storage_endpoint" {
    description = "This blob storage will hold all Threat Detection audit logs. Required if state is Enabled."
    type        = string
}

variable "storage_account_access_key" {
    description = "Specifies the identifier key of the Threat Detection audit storage account. Required if state is Enabled."
    type        = string
}

variable "ad_admin_login_name" {
    description = "The login name of the principal to set as the server administrator"
    type        = string
}

variable "enable_sql_ad_admin" {
    description = "Allows you to set a user or group as the AD administrator for an Azure SQL server"
    type        = bool
    default     = false
}

variable "firewall_rules" {
  description = "Range of IP addresses to allow firewall connections."
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

##
# Optional Parameters
##

variable "administrator_login" {
    type        = string
    description = "Database administrator login name"
    default     = "AZSysadmin"
}

variable "zone_redundant" {
    type        = string
    description = "Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones. This property is only settable for Premium and Business Critical databases."
    default     = "false"
}

variable "license_type" {
    type        = string
    description = "Specifies the license type applied to this database. Possible values are LicenseIncluded and BasePrice."
    default     = "LicenseIncluded"
}

variable "read_scale" {
    type        = string
    description = "If enabled, connections that have application intent set to readonly in their connection string may be routed to a readonly secondary replica. This property is only settable for Premium and Business Critical databases."
    default     = "false"
}

variable "collation" {
    type        = string
    description = "Specifies the collation of the database."
    default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "read_replica_count" {
    type        = string
    description = "The number of readonly secondary replicas associated with the database to which readonly application intent connections may be routed. This property is only settable for Hyperscale edition databases."
    default     = "0"
}

