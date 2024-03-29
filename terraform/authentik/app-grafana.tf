module "onepassword_grafana" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "grafana"
}

module "grafana" {
  source                 = "./modules/oidc-application"
  name                   = "grafana"
  domain                 = "grafana.${local.cluster_domain}"
  group                  = "Monitoring"
  client_id              = module.onepassword_grafana.fields.AUTHENTIK_CLIENT_ID
  client_secret          = module.onepassword_grafana.fields.AUTHENTIK_CLIENT_SECRET
  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  redirect_uris          = ["https://grafana.${local.cluster_domain}/login/generic_oauth"]
  access_token_validity  = "hours=4"
  authentik_domain       = "sso.${local.cluster_domain}"
  meta_icon              = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/grafana.png"
  meta_launch_url        = "https://grafana.${local.cluster_domain}/login/generic_oauth"
  property_mappings = [
    data.authentik_scope_mapping.scope-email.id,
    data.authentik_scope_mapping.scope-profile.id,
    data.authentik_scope_mapping.scope-openid.id,
  ]
}

resource "authentik_group" "grafana_admins" {
  name = "Grafana Admins"
}

resource "authentik_group" "grafana_editors" {
  name = "Grafana Editors"
}

resource "authentik_group" "grafana_viewers" {
  name = "Grafana Viewers"
}

resource "authentik_policy_binding" "grafana-access-admin" {
  target = module.grafana.application_id
  group  = authentik_group.grafana_admins.id
  order  = 0
}

resource "authentik_policy_binding" "grafana-access-editors" {
  target = module.grafana.application_id
  group  = authentik_group.grafana_editors.id
  order  = 0
}

resource "authentik_policy_binding" "grafana-access-viewers" {
  target = module.grafana.application_id
  group  = authentik_group.grafana_viewers.id
  order  = 0
}
