module "whoami" {
  source = "./modules/forward-auth-application"
  slug   = "whoami"

  name   = "Who Am I"
  domain = "whoami.${local.cluster_domain}"
  group  = authentik_group.infrastructure.name

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/libreoffice.png"
}

resource "authentik_group" "whoami_users" {
  name = "WhoAmI Users"
}

resource "authentik_policy_binding" "whoami-access-users" {
  target = module.whoami.application_id
  group  = authentik_group.whoami_users.id
  order  = 0
}
