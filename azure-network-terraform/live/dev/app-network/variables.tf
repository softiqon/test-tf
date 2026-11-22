variable "subscription_id" {
  description = "Target subscription."
  type        = string
}

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "location_short" {
  type    = string
  default = "aue"
}

variable "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace for diagnostics. null disables."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "workload" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "create_resource_group" {
  type    = bool
  default = true
}

variable "address_space" {
  type = set(string)
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

# Schema is enforced by patterns/vnet (typed + validated there).
variable "route_tables" {
  type    = any
  default = {}
}

variable "subnets" {
  type    = any
  default = {}
}
