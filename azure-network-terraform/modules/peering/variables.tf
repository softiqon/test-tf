variable "name" {
  description = "Name of the local -> remote peering."
  type        = string
}

variable "local_virtual_network_id" {
  description = "VNet the forward peering is created in."
  type        = string
}

variable "remote_virtual_network_id" {
  description = "VNet being peered to."
  type        = string
}

variable "location" {
  description = "Region (used by AVM telemetry)."
  type        = string
}

variable "allow_forwarded_traffic" {
  type    = bool
  default = false
}

variable "allow_gateway_transit" {
  type    = bool
  default = false
}

variable "use_remote_gateways" {
  description = "Use the remote VNet's gateway. The remote must have a gateway, or the apply fails."
  type        = bool
  default     = false
}

variable "create_reverse_peering" {
  type    = bool
  default = true
}

variable "reverse_name" {
  description = "Name of the remote -> local peering."
  type        = string
  default     = null
}

variable "reverse_allow_forwarded_traffic" {
  type    = bool
  default = false
}

variable "reverse_allow_gateway_transit" {
  type    = bool
  default = false
}

variable "reverse_use_remote_gateways" {
  type    = bool
  default = false
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
