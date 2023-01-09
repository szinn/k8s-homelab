module "onepassword_minio_bucket_thanos" {
  source      = "./modules/onepassword_minio_bucket"
  bucket_name = "thanos"
  vault         = "Kubernetes"
  password_item = "thanos"
  providers = {
    minio = minio.atlas
  }
}
