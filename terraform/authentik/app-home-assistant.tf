module "home_assistant" {
  source = "./modules/forward-auth-application"
  slug   = "homeassistant"

  name          = "Home Assistant"
  domain        = "home.${local.cluster_domain}"
  internal_host = "https://home.zinn.ca"
  group         = authentik_group.applications.name

  policy_engine_mode       = "any"
  authentication_flow_uuid = authentik_flow.authentication.uuid
  authorization_flow_uuid  = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/home-assistant.png"
  meta_launch_url = "https://home.zinn.ca/lovelace-home/default_view"
}

resource "authentik_group" "home_assistant_users" {
  name = "Home Assistant Users"
}

resource "authentik_policy_binding" "home_assistant-access-users" {
  target = module.home_assistant.application_id
  group  = authentik_group.home_assistant_users.id
  order  = 0
}
