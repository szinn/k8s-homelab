terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
    }
  }
}

variable "name" {
  type = string
}
variable "domain" {
  type = string
}
variable "access_token_validity" {
  type    = string
  default = "weeks=8"
}
variable "authorization_flow_uuid" {
  type = string
}

variable "meta_icon" {
  type    = string
  default = null
}
variable "group" {
  type = string
}
variable "policy_engine_mode" {
  type    = string
  default = "all"
}

variable "mode" {
  type    = string
  default = "forward_single"
}

variable "internal_host" {
  type    = string
  default = null
}
variable "basic_auth_enabled" {
  type    = bool
  default = false
}
variable "basic_auth_password_attribute" {
  type    = string
  default = null
}
variable "basic_auth_username_attribute" {
  type    = string
  default = null
}

variable "property_mappings" {
  type    = list(string)
  default = null
}
variable "skip_path_regex" {
  type    = string
  default = null
}
resource "authentik_provider_proxy" "main" {
  name                          = var.name
  external_host                 = "https://${var.domain}"
  internal_host                 = var.internal_host
  basic_auth_enabled            = var.basic_auth_enabled
  basic_auth_password_attribute = var.basic_auth_password_attribute
  basic_auth_username_attribute = var.basic_auth_username_attribute
  mode                          = var.mode
  authorization_flow            = var.authorization_flow_uuid
  access_token_validity         = var.access_token_validity
  property_mappings             = var.property_mappings
  skip_path_regex               = var.skip_path_regex
}


resource "authentik_application" "main" {
  name               = title(var.name)
  slug               = var.name
  protocol_provider  = authentik_provider_proxy.main.id
  group              = var.group
  open_in_new_tab    = true
  meta_icon          = var.meta_icon
  policy_engine_mode = var.policy_engine_mode
}

output "application_id" {
  value = authentik_application.main.uuid
}
output "proxy_provider_id" {
  value = authentik_provider_proxy.main.id
}
