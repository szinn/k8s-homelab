terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
    }
  }
}

module "onepassword_item" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = var.vault
  item   = var.password_item
}

module "minio_bucket" {
  source      = "../minio_bucket"
  bucket_name = module.onepassword_item.fields.aws_bucket_name
  user_name   = module.onepassword_item.fields.aws_access_key_id
  user_secret = module.onepassword_item.fields.aws_secret_access_key
}
