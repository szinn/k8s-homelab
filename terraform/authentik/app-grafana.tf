module "onepassword_grafana" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "grafana"
}

module "grafana" {
  source = "./modules/oidc-application"
  slug   = "grafana"

  name   = "Grafana"
  domain = "grafana.${local.cluster_domain}"
  group  = authentik_group.monitoring.name

  client_id     = "grafana"
  client_secret = module.onepassword_grafana.fields.AUTHENTIK_CLIENT_SECRET

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = ["https://grafana.${local.cluster_domain}/login/generic_oauth"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/grafana.png"
  meta_launch_url = "https://grafana.${local.cluster_domain}/login/generic_oauth"
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
