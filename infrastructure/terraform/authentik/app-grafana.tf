module "onepassword_grafana" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "grafana"
}

resource "authentik_provider_oauth2" "grafana" {
  name          = "Grafana"

  client_id     = module.onepassword_grafana.fields.AUTHENTIK_CLIENT_ID
  client_secret = module.onepassword_grafana.fields.AUTHENTIK_CLIENT_SECRET

  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id

  redirect_uris = [module.onepassword_grafana.fields.AUTHENTIK_GRAFANA_URL]

  property_mappings = [
    data.authentik_scope_mapping.scope-email.id,
    data.authentik_scope_mapping.scope-profile.id,
    data.authentik_scope_mapping.scope-openid.id,
  ]
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id

  meta_launch_url = module.onepassword_grafana.fields.AUTHENTIK_GRAFANA_URL
}

resource "authentik_group" "grafana_admins" {
  name    = "Grafana Admins"
}

resource "authentik_group" "grafana_editors" {
  name    = "Grafana Editors"
}

resource "authentik_group" "grafana_viewers" {
  name    = "Grafana Viewers"
}

resource "authentik_policy_binding" "grafana-access-admin" {
  target = authentik_application.grafana.uuid
  group  = authentik_group.grafana_admins.id
  order  = 0
}

resource "authentik_policy_binding" "grafana-access-editors" {
  target = authentik_application.grafana.uuid
  group  = authentik_group.grafana_editors.id
  order  = 0
}

resource "authentik_policy_binding" "grafana-access-viewers" {
  target = authentik_application.grafana.uuid
  group  = authentik_group.grafana_viewers.id
  order  = 0
}
