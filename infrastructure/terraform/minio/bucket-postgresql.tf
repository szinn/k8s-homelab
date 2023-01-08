module "onepassword_item_postgreql" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "postgres-minio"
}

module "minio_bucket_postgresql" {
  source      = "./modules/minio_bucket"
  bucket_name = "postgresql"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_postgreql.fields.aws_access_key_id
  user_secret = module.onepassword_item_postgreql.fields.aws_secret_access_key
}
