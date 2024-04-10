module "onepassword_minio_bucket_loki" {
  source        = "./modules/onepassword_minio_bucket"
  vault         = "Kubernetes"
  password_item = "loki"
  bucket_names  = ["loki-chunks", "loki-ruler"]
}
