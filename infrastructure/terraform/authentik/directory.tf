resource "authentik_group" "users" {
  name         = "users"
  is_superuser = false
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

resource "authentik_user" "scotte" {
  username = module.onepassword_scotte.fields.username
  name     = module.onepassword_scotte.fields.FULLNAME
  email    = module.onepassword_scotte.fields.EMAIL
  password = module.onepassword_scotte.fields.password
  groups   = [data.authentik_group.admins.id, authentik_group.users.id]
}
