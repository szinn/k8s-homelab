module "onepassword_item" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = var.vault
  item   = var.password_item
}

module "minio_bucket" {
  source       = "../minio_bucket"
  bucket_names = var.bucket_names
  user_name    = module.onepassword_item.fields.AWS_ACCESS_KEY_ID
  user_secret  = module.onepassword_item.fields.AWS_SECRET_ACCESS_KEY
}
