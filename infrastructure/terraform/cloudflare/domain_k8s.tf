# tf import module.cf_domain_k8s.cloudflare_zone.zone "<zone_id>"
module "cf_domain_k8s" {
  source     = "./modules/cf_domain"
  domain     = local.k8s_zone
  account_id = cloudflare_account.main.id
  dns_entries = [
    {
      id      = "calendar"
      name    = "calendar"
      value   = "ghs.google.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "docs"
      name    = "docs"
      value   = "ghs.google.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "mail"
      name    = "mail"
      value   = "ghs.google.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id       = "aspmx4"
      name     = "gmail"
      priority = 10
      value    = "aspmx4.googlemail.com"
      type     = "MX"
    },
    {
      id       = "aspmx2"
      name     = "gmail"
      priority = 10
      value    = "aspmx2.googlemail.com"
      type     = "MX"
    },
    {
      id       = "aspmx3"
      name     = "gmail"
      priority = 10
      value    = "aspmx3.googlemail.com"
      type     = "MX"
    },
    {
      id       = "alt2"
      name     = "gmail"
      priority = 5
      value    = "alt2.aspmx.l.google.com"
      type     = "MX"
    },
    {
      id       = "alt1"
      name     = "gmail"
      priority = 5
      value    = "alt1.aspmx.l.google.com"
      type     = "MX"
    },
    {
      id       = "aspmx"
      name     = "gmail"
      value    = "aspmx.l.google.com"
      type     = "MX"
    },
    {
      id    = "_dmarc"
      name  = "_dmarc"
      value = "v=DMARC1; p=reject; rua=mailto:dmarc@magized.com"
      type  = "TXT"
    },
    {
      id    = "google_domainkey"
      name  = "google._domainkey"
      value = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCa8oSZnG8mT99RyI1Clgfraknk0qvs6rcse74d6lwYCoNhQQ0IVLNp7bOCSgPi8vBzuvSPK5Q7ZDoofaZ+D7wYXkxXlQHnJrj2dVleFKiEtFFlgmAnlr9elzSKET46Ow+fsHk2D6Vxg8w8pFa9GZ4sv+FqFv0jbW4YVYz6RxUbfQIDAQAB"
      type  = "TXT"
    },
    {
      id    = "google_spf"
      name  = "zinn.ca"
      value = "v=spf1 include:_spf.google.com ~all"
      type  = "TXT"
    }
  ]
  waf_custom_rules = [
    {
      enabled     = true
      description = "Allow GitHub flux API"
      expression  = "(ip.geoip.asnum eq 36459 and http.host eq \"flux-receiver.zinn.ca\")"
      action      = "skip"
      action_parameters = {
        ruleset = "current"
      }
      logging = {
        enabled = false
      }
    },
    {
      enabled     = true
      description = "Firewall rule to block bots and threats determined by CF"
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
    },
    {
      enabled     = true
      description = "Firewall rule to block all countries except CA/US"
      expression  = "(ip.geoip.country ne \"CA\") and (ip.geoip.country ne \"US\")"
      action      = "block"
    }
  ]
}
