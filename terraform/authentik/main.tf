terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.2.0"
    }
  }
}

provider "authentik" {
  url   = module.onepassword_authentik.fields.URL
  token = module.onepassword_authentik.fields.BOOTSTRAP_TOKEN
}

module "onepassword_authentik" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "authentik"
}

resource "authentik_service_connection_kubernetes" "local" {
  name       = "local"
  local      = true
  verify_ssl = false
}

locals {
  internal_proxy_provider_ids = [
    module.whoami.proxy_provider_id
  ]
}
