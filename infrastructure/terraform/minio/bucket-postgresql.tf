module "onepassword_minio_bucket_postgresql" {
  source        = "./modules/onepassword_minio_bucket"
  vault         = "Kubernetes"
  password_item = "postgres-minio"
  providers = {
    minio = minio.atlas
  }
}
