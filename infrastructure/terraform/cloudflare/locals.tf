locals {
  home_ipv4 = chomp(data.http.ipv4_lookup_raw.response_body)
  k8s_zone  = module.onepassword_item_cloudflare.fields["zone"]
  tech_zone = module.onepassword_item_cloudflare.fields["tech_zone"]
  account_name = module.onepassword_item_cloudflare.fields["account_name"]
}
