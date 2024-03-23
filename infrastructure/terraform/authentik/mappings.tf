data "authentik_scope_mapping" "email" {
  managed = "goauthentik.io/providers/oauth2/scope-email"
}

data "authentik_scope_mapping" "profile" {
  managed = "goauthentik.io/providers/oauth2/scope-profile"
}

data "authentik_scope_mapping" "openid" {
  managed = "goauthentik.io/providers/oauth2/scope-openid"
}

data "authentik_property_mapping_saml" "upn" {
  managed = "goauthentik.io/providers/saml/upn"
}

data "authentik_property_mapping_saml" "name" {
  managed = "goauthentik.io/providers/saml/name"
}

data "authentik_property_mapping_saml" "groups" {
  managed = "goauthentik.io/providers/saml/groups"
}

data "authentik_property_mapping_saml" "username" {
  managed = "goauthentik.io/providers/saml/username"
}

data "authentik_property_mapping_saml" "email" {
  managed = "goauthentik.io/providers/saml/email"
}
