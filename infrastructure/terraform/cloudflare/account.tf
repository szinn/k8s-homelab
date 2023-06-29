# tf import cloudflare_account.main "<account_id>"
resource "cloudflare_account" "main" {
  name              = local.account_name
  type              = "standard"
  enforce_twofactor = false
}
