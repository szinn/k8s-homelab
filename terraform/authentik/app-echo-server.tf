module "echo_server" {
  source = "./modules/forward-auth-application"
  slug   = "echo_server"

  name   = "Echo Server"
  domain = "echo-server.${local.cluster_domain}"
  group  = authentik_group.infrastructure.name

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/web-check.png"
}

resource "authentik_group" "echo_server_users" {
  name = "Echo Server Users"
}

resource "authentik_policy_binding" "echo_server-access-users" {
  target = module.echo_server.application_id
  group  = authentik_group.echo_server_users.id
  order  = 0
}
