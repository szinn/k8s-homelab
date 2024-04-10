module "onepassword_minio_bucket_volsync" {
  source        = "./modules/onepassword_minio_bucket"
  vault         = "Kubernetes"
  password_item = "volsync"
  bucket_names  = ["volsync"]
}
