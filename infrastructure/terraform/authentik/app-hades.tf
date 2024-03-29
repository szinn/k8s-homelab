module "onepassword_hades" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "hades"
}

resource "authentik_provider_oauth2" "hades" {
  name                   = "Synology - Hades"
  access_token_validity  = "hours=4"
  refresh_token_validity = "days=365"

  client_id     = module.onepassword_hades.fields.AUTHENTIK_CLIENT_ID
  client_secret = module.onepassword_hades.fields.AUTHENTIK_CLIENT_SECRET

  authentication_flow = authentik_flow.authentication.uuid
  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id

  signing_key = data.authentik_certificate_key_pair.generated.id

  redirect_uris = [module.onepassword_hades.fields.AUTHENTIK_REDIRECT_URL]

  property_mappings = [
    data.authentik_scope_mapping.scope-email.id,
    data.authentik_scope_mapping.scope-profile.id,
    data.authentik_scope_mapping.scope-openid.id,
  ]
}

resource "authentik_application" "hades" {
  name              = "Synology - Hades"
  slug              = "hades"
  protocol_provider = authentik_provider_oauth2.hades.id
  group             = authentik_group.infrastructure.name
  open_in_new_tab   = true

  meta_icon       = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/synology-drive-server.png"
  meta_launch_url = module.onepassword_hades.fields.AUTHENTIK_REDIRECT_URL
}

resource "authentik_group" "hades_user" {
  name = "Hades User"
}

resource "authentik_policy_binding" "hades-access-users" {
  target = authentik_application.hades.uuid
  group  = authentik_group.hades_user.id
  order  = 0
}
