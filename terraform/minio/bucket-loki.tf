module "onepassword_minio_bucket_loki" {
  source        = "./modules/onepassword_minio_bucket"
  vault         = "Kubernetes"
  password_item = "loki"
  providers = {
    minio = minio.atlas
  }
}
