module "onepassword_item_volsync" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "volsync"
}

module "minio_bucket_volsync" {
  source      = "./modules/minio_bucket"
  bucket_name = "volsync"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_volsync.fields.aws_access_key_id
  user_secret = module.onepassword_item_volsync.fields.aws_secret_access_key
}
