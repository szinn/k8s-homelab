module "onepassword_item_thanos" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "thanos"
}

module "minio_bucket_thanos" {
  source      = "./modules/minio_bucket"
  bucket_name = "thanos"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_thanos.fields.aws_access_key_id
  user_secret = module.onepassword_item_thanos.fields.aws_secret_access_key
}
