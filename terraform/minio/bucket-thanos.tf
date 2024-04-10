module "onepassword_minio_bucket_thanos" {
  source        = "./modules/onepassword_minio_bucket"
  vault         = "Kubernetes"
  password_item = "thanos"
  bucket_names  = ["thanos"]
}
