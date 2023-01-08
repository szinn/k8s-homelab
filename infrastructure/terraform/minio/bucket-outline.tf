module "onepassword_item_outline" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "outline"
}

module "minio_bucket_outline" {
  source      = "./modules/minio_bucket"
  bucket_name = "outline"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_outline.fields.aws_access_key_id
  user_secret = module.onepassword_item_outline.fields.aws_secret_access_key
}
