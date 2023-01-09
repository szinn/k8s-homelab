module "onepassword_minio_bucket_loki" {
  source      = "./modules/onepassword_minio_bucket"
  bucket_name = "loki"
  vault         = "Kubernetes"
  password_item = "loki"
  providers = {
    minio = minio.atlas
  }
}
