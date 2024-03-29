
locals {
  cluster_domain   = module.onepassword_authentik.fields.CLUSTER_DOMAIN
  authentik_domain = "sso.${local.cluster_domain}"
}
