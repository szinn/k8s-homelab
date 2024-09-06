module "onepassword_item_minio" {
  source = "github.com/bernd-schorgers/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "minio-ragnar"
}
