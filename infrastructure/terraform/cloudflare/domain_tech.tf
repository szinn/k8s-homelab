# tf import module.cf_domain_tech.cloudflare_zone.zone "<zone_id>"
module "cf_domain_tech" {
  source     = "./modules/cf_domain"
  domain     = local.tech_zone
  account_id = cloudflare_account.main.id
  dns_entries = [
    {
      id    = "_dmarc"
      name  = "_dmarc"
      value = "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;"
      type  = "TXT"
    },
    {
      id    = "_domainkey"
      name  = "*._domainkey"
      value = "v=DKIM1; p="
      type  = "TXT"
    },
    {
      id    = "_spf"
      name  = "zinn.tech"
      value = "v=spf1 ~all"
      type  = "TXT"
    }
  ]
  waf_custom_rules = [
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
