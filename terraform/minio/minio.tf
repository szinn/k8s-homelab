module "onepassword_item_minio" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "minio-admin"
}

module "onepassword_item_loki" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "loki"
}

module "minio_bucket_loki" {
  source      = "./modules/minio_bucket"
  bucket_name = "loki"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_loki.fields.aws_access_key_id
  user_secret = module.onepassword_item_loki.fields.aws_secret_access_key
}

module "onepassword_item_thanos" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "thanos"
}

module "minio_bucket_thanos" {
  source      = "./modules/minio_bucket"
  bucket_name = "thanos"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_thanos.fields.aws_access_key_id
  user_secret = module.onepassword_item_thanos.fields.aws_secret_access_key
}

module "onepassword_item_postgreql" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "postgres-minio"
}

module "minio_bucket_postgresql" {
  source      = "./modules/minio_bucket"
  bucket_name = "postgresql"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_postgreql.fields.aws_access_key_id
  user_secret = module.onepassword_item_postgreql.fields.aws_secret_access_key
}

module "onepassword_item_volsync" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "volsync"
}

module "minio_bucket_volsync" {
  source      = "./modules/minio_bucket"
  bucket_name = "volsync"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_volsync.fields.aws_access_key_id
  user_secret = module.onepassword_item_volsync.fields.aws_secret_access_key
}

module "onepassword_item_outline" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "outline"
}

module "minio_bucket_outline" {
  source      = "./modules/minio_bucket"
  bucket_name = "outline"
  providers = {
    minio = minio.atlas
  }
  user_name   = module.onepassword_item_outline.fields.aws_access_key_id
  user_secret = module.onepassword_item_outline.fields.aws_secret_access_key
}
