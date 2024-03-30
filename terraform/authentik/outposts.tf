locals {
  internal_proxy_provider_ids = [
    module.whoami.proxy_provider_id
  ]

  external_proxy_provider_ids = [
    module.echo_server.proxy_provider_id
  ]
}

resource "authentik_outpost" "internal" {
  name               = "internal"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = local.internal_proxy_provider_ids
  config = jsonencode({
    "log_level"                      = "info"
    "docker_labels"                  = null
    "authentik_host"                 = "https://sso.${local.cluster_domain}/"
    "docker_network"                 = null
    "container_image"                = null
    "docker_map_ports"               = true
    "kubernetes_replicas"            = 1
    "kubernetes_namespace"           = "security"
    "authentik_host_browser"         = ""
    "object_naming_template"         = "ak-outpost-%(name)s"
    "authentik_host_insecure"        = false
    "kubernetes_json_patches"        = null
    "kubernetes_service_type"        = "ClusterIP"
    "kubernetes_image_pull_secrets"  = []
    "kubernetes_ingress_class_name"  = "internal"
    "kubernetes_disabled_components" = []
    "kubernetes_ingress_annotations" = {}
    "kubernetes_ingress_secret_name" = "authentik-outpost-tls"
  })
}

resource "authentik_outpost" "external" {
  name               = "external"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = local.external_proxy_provider_ids
  config = jsonencode({
    "log_level"                      = "info"
    "docker_labels"                  = null
    "authentik_host"                 = "https://sso.${local.cluster_domain}/"
    "docker_network"                 = null
    "container_image"                = null
    "docker_map_ports"               = true
    "kubernetes_replicas"            = 1
    "kubernetes_namespace"           = "security"
    "authentik_host_browser"         = ""
    "object_naming_template"         = "ak-outpost-%(name)s"
    "authentik_host_insecure"        = false
    "kubernetes_json_patches"        = null
    "kubernetes_service_type"        = "ClusterIP"
    "kubernetes_image_pull_secrets"  = []
    "kubernetes_ingress_class_name"  = "external"
    "kubernetes_disabled_components" = []
    "kubernetes_ingress_annotations" = {
      "external-dns/is-public" : "true"
      "external-dns.alpha.kubernetes.io/target" : "external.${local.cluster_domain}"
    }
    "kubernetes_ingress_secret_name" = "authentik-outpost-tls"
  })
}
