module "onepassword_minio_bucket_parseable" {
  source        = "./modules/onepassword_minio_bucket"
  vault         = "Kubernetes"
  password_item = "parseable"
  providers = {
    minio = minio
  }
}
