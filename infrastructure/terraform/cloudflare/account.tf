# tf import cloudflare_account.main "<account_id>"
resource "cloudflare_account" "main" {
  name              = "Scotte@zinn.ca's Account"
  type              = "standard"
  enforce_twofactor = false
}
