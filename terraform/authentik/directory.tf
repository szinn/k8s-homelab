data "authentik_group" "admins" {
  name = "authentik Admins"
}

resource "authentik_group" "users" {
  name         = "users"
  is_superuser = false
}

resource "authentik_group" "infrastructure" {
  name         = "Infrastructure"
  is_superuser = false
}

resource "authentik_group" "monitoring" {
  name         = "Monitoring"
  is_superuser = false
}

resource "authentik_group" "applications" {
  name         = "Applications"
  is_superuser = false
}

module "onepassword_scotte" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "scotte-credentials"
}

resource "authentik_user" "scotte" {
  username = module.onepassword_scotte.fields.username
  name     = module.onepassword_scotte.fields.FULLNAME
  email    = module.onepassword_scotte.fields.EMAIL
  password = module.onepassword_scotte.fields.password
  groups = [
    data.authentik_group.admins.id,
    authentik_group.users.id,
    authentik_group.grafana_admins.id,
    authentik_group.wikijs_users.id,
    authentik_group.hades_users.id,
    authentik_group.whoami_users.id,
    authentik_group.echo_server_users.id,
    # authentik_group.home_assistant_users.id,
  ]
}

module "onepassword_sophie" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "sophie-credentials"
}

resource "authentik_user" "sophie" {
  username = module.onepassword_sophie.fields.username
  name     = module.onepassword_sophie.fields.FULLNAME
  email    = module.onepassword_sophie.fields.EMAIL
  password = module.onepassword_sophie.fields.password
  groups = [
    authentik_group.users.id,
    authentik_group.wikijs_users.id,
    # authentik_group.home_assistant_users.id,
  ]
}
