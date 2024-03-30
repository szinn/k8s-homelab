module "onepassword_hades" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "hades"
}

module "hades" {
  source = "./modules/oidc-application"
  slug   = "hades"

  name   = "Synology - Hades"
  domain = "hades.${local.cluster_domain}"
  group  = authentik_group.infrastructure.name

  client_id     = "hades"
  client_secret = module.onepassword_hades.fields.AUTHENTIK_CLIENT_SECRET

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id

  redirect_uris = [module.onepassword_hades.fields.AUTHENTIK_REDIRECT_URL]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/synology-drive-server.png"
  meta_launch_url = module.onepassword_hades.fields.AUTHENTIK_REDIRECT_URL

  property_mappings = [
    data.authentik_scope_mapping.scope-email.id,
    data.authentik_scope_mapping.scope-profile.id,
    data.authentik_scope_mapping.scope-openid.id,
  ]
}

resource "authentik_group" "hades_users" {
  name = "Hades Users"
}

resource "authentik_policy_binding" "hades-access-users" {
  target = module.hades.application_id
  group  = authentik_group.hades_users.id
  order  = 0
}
