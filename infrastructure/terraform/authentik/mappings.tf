data "authentik_scope_mapping" "email" {
  managed = "goauthentik.io/providers/oauth2/scope-email"
}

data "authentik_scope_mapping" "profile" {
  managed = "goauthentik.io/providers/oauth2/scope-profile"
}

data "authentik_scope_mapping" "openid" {
  managed = "goauthentik.io/providers/oauth2/scope-openid"
}

data "authentik_scope_mapping" "scope-email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}

data "authentik_scope_mapping" "scope-profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}

data "authentik_scope_mapping" "scope-openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

data "authentik_scope_mapping" "oauth2" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}
