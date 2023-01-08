module "onepassword_item_loki" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "loki"
}

module "minio_bucket_loki" {
  source      = "./modules/minio_bucket"
  bucket_name = "loki"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_loki.fields.aws_access_key_id
  user_secret = module.onepassword_item_loki.fields.aws_secret_access_key
}
