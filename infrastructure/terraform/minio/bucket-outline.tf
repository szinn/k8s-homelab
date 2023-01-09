module "onepassword_minio_bucket_outline" {
  source      = "./modules/onepassword_minio_bucket"
  bucket_name = "outline"
  vault         = "Kubernetes"
  password_item = "outline"
  providers = {
    minio = minio.atlas
  }
}
