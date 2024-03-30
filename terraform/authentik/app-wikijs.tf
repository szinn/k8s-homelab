module "onepassword_wikijs" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "wikijs"
}

module "wikijs" {
  source = "./modules/oidc-application"
  slug   = "wikijs"

  name   = "WilZinn Wiki"
  domain = "wiki.${local.cluster_domain}"
  group  = authentik_group.applications.name

  client_id     = "wikijs"
  client_secret = module.onepassword_wikijs.fields.AUTHENTIK_CLIENT_SECRET

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id

  redirect_uris = [module.onepassword_wikijs.fields.AUTHENTIK_CALLBACK_URL]

  access_token_validity = "hours=4"

  meta_icon       = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/wikijs.png"
  meta_launch_url = "https://wiki.${local.cluster_domain}/login"

  property_mappings = [
    data.authentik_scope_mapping.scope-email.id,
    data.authentik_scope_mapping.scope-profile.id,
    data.authentik_scope_mapping.scope-openid.id,
  ]
}

resource "authentik_group" "wikijs_users" {
  name = "Wiki Users"
}

resource "authentik_policy_binding" "wikijs-access-users" {
  target = module.wikijs.application_id
  group  = authentik_group.wikijs_users.id
  order  = 0
}
