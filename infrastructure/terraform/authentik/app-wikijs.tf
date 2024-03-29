module "onepassword_wikijs" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "wikijs"
}

resource "authentik_provider_oauth2" "wikijs" {
  name                   = "Wiki"
  access_token_validity  = "hours=4"
  refresh_token_validity = "days=365"

  client_id     = module.onepassword_wikijs.fields.AUTHENTIK_CLIENT_ID
  client_secret = module.onepassword_wikijs.fields.AUTHENTIK_CLIENT_SECRET

  authentication_flow = authentik_flow.authentication.uuid
  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id

  signing_key = data.authentik_certificate_key_pair.generated.id

  redirect_uris = [module.onepassword_wikijs.fields.AUTHENTIK_CALLBACK_URL]

  property_mappings = [
    data.authentik_scope_mapping.scope-email.id,
    data.authentik_scope_mapping.scope-profile.id,
    data.authentik_scope_mapping.scope-openid.id,
  ]
}

resource "authentik_application" "wikijs" {
  name              = "Wiki"
  slug              = "wikijs"
  protocol_provider = authentik_provider_oauth2.wikijs.id
  group             = authentik_group.applications.name
  open_in_new_tab   = true

  meta_icon       = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/wikijs.png"
  meta_launch_url = "https://wiki.${local.cluster_domain}/login"
}

resource "authentik_group" "wikijs_family" {
  name = "Family"
}

resource "authentik_policy_binding" "wikijs-access-users" {
  target = authentik_application.wikijs.uuid
  group  = authentik_group.wikijs_family.id
  order  = 0
}
