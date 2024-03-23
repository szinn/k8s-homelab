resource "authentik_group" "users" {
  name         = "users"
  is_superuser = false
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

##Oauth
# resource "authentik_source_oauth" "discord" {
#   name                = "Discord"
#   slug                = "discord"
#   authentication_flow = data.authentik_flow.default-source-authentication.id
#   enrollment_flow     = authentik_flow.enrollment-invitation.uuid
#   user_matching_mode  = "email_deny"

#   provider_type   = "discord"
#   consumer_key    = module.onepassword_discord.fields.DISCORD_BOT_ID
#   consumer_secret = module.onepassword_discord.fields.DISCORD_TOKEN
# }

resource "authentik_source_oauth" "twitter" {
  name                = "Twitter"
  slug                = "twitter"
  authentication_flow = data.authentik_flow.default-source-authentication.id
  enrollment_flow     = authentik_flow.enrollment-invitation.uuid
  user_matching_mode  = "email_deny"

  provider_type   = "twitter"
  consumer_key    = module.onepassword_twitter.fields.CLIENT_ID
  consumer_secret = module.onepassword_twitter.fields.CLIENT_SECRET
}

resource "authentik_source_oauth" "google" {
  name                = "Google"
  slug                = "google"
  authentication_flow = data.authentik_flow.default-source-authentication.id
  enrollment_flow     = authentik_flow.enrollment-invitation.uuid
  user_matching_mode  = "email_deny"

  provider_type   = "google"
  consumer_key    = module.onepassword_google.fields.CLIENT_ID
  consumer_secret = module.onepassword_google.fields.CLIENT_SECRET

  access_token_url  = "https://oauth2.googleapis.com/token"
  authorization_url = "https://accounts.google.com/o/oauth2/v2/auth"
  oidc_jwks_url     = "https://www.googleapis.com/oauth2/v3/certs"
  profile_url       = "https://openidconnect.googleapis.com/v1/userinfo"
}
