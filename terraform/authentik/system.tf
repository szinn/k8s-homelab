resource "authentik_brand" "home" {
  domain           = module.onepassword_authentik.fields.CLUSTER_DOMAIN
  branding_title   = "WilZinn World"
  branding_logo    = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon = "/static/dist/assets/icons/icon.png"

  flow_authentication = authentik_flow.authentication.uuid
  flow_invalidation   = authentik_flow.invalidation.uuid
  flow_user_settings  = authentik_flow.user-settings.uuid
}
