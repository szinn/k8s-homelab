# tf import module.cf_domain_tech.cloudflare_zone.zone "<zone_id>"
module "cf_domain_tech" {
  source     = "./modules/cf_domain"
  domain     = local.tech_zone
  account_id = cloudflare_account.main.id
  dns_entries = [
    {
      id       = "smtp"
      name     = "@"
      priority = 10
      value    = "magized.com."
      type     = "MX"
      ttl      = 600
    },
    {
      id    = "_domainkey"
      name  = "dkim._domainkey"
      value = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt4QPJ4DQtVk5pYFSe2h29HDQCwdzx91jS3FTi6qaLU56FYkfhi80kmbCazMLPMAZoq2jbdha46Uak+4jKKQIMBqp2KpVOATAf9J2IX0EIDuwAvw6DS3hElAHxFUTboqJTDeoABg8GipGVZJ7fGdZ8bvxR4KNQn0aIDw6ecFl1+p7mIKHsucJ9Ryk0l17oS7un79drCeZPAO7aZ0/u0LlYW58akMs7Nuht/eKjHFW538PhHYTf1xckFK/qLSqrzHPwgnzE7r2jQtJt9vj/YLv40EsQ8NI8ySN14nyZIKqrnwKTkqfdUqVNHkVlpj8bLjUn6PclgHFwp+fQE5VQicxEQIDAQAB"
      type  = "TXT"
      ttl   = 600
    },
    {
      id    = "_dmarc"
      name  = "_dmarc"
      value = "v=DMARC1; p=reject; rua=mailto:dmarc@magized.com; ruf=mailto:dmarc@magized.com; adkim=s; aspf=s"
      type  = "TXT"
      ttl   = 600
    },
    {
      id    = "_spf"
      name  = "zinn.tech"
      value = "v=spf1 mx a:magized.com ~all"
      type  = "TXT"
      ttl   = 600
    }
    # {
    #   id    = "_tlsa"
    #   name  = "_25._tcp"
    #   value = "2 1 1 0b9fa5a59eed715c26c1020c711b4f6ec42d58b0015e14337a39dad301c5afc3"
    #   type  = "TLSA"
    #   ttl   = 86400
    # }
  ]
  waf_custom_rules = [
    {
      enabled     = true
      description = "Firewall rule to block bots and threats determined by CF"
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
    }
  ]
}
