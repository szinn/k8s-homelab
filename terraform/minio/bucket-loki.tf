# module "onepassword_minio_bucket_loki" {
#   source        = "./modules/onepassword_minio_bucket"
#   vault         = "Kubernetes"
#   password_item = "loki"
#   providers = {
#     minio = minio.atlas
#   }
# }

module "onepassword_loki" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Kubernetes"
  item   = "loki"
}

resource "minio_s3_bucket" "loki_chunks" {
  bucket = "loki-chunks"
  acl    = "private"
}

resource "minio_s3_bucket_policy" "loki_chunks" {
  bucket = minio_s3_bucket.loki_chunks.bucket
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Resource": ["arn:aws:s3:::${minio_s3_bucket.loki_chunks.bucket}"],
      "Action": ["s3:ListBucket"]
    }
  ]
}
EOF
}

resource "minio_s3_bucket" "loki_ruler" {
  bucket = "loki-ruler"
  acl    = "private"
}

resource "minio_s3_bucket_policy" "loki_ruler" {
  bucket = minio_s3_bucket.loki_ruler.bucket
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Resource": ["arn:aws:s3:::${minio_s3_bucket.loki_ruler.bucket}"],
      "Action": ["s3:ListBucket"]
    }
  ]
}
EOF
}

resource "minio_s3_bucket" "loki_admin" {
  bucket = "loki-admin"
  acl    = "private"
}

resource "minio_s3_bucket_policy" "loki_admin" {
  bucket = minio_s3_bucket.loki_admin.bucket
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Resource": ["arn:aws:s3:::${minio_s3_bucket.loki_admin.bucket}"],
      "Action": ["s3:ListBucket"]
    }
  ]
}
EOF
}

resource "minio_iam_user" "loki" {
  name = module.onepassword_loki.fields.AWS_ACCESS_KEY_ID
  secret = module.onepassword_loki.fields.AWS_SECRET_ACCESS_KEY
  force_destroy = true
}

resource "minio_iam_policy" "loki_rw_policy" {
  name   = minio_iam_user.loki.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::${minio_s3_bucket.loki_chunks.bucket}",
                "arn:aws:s3:::${minio_s3_bucket.loki_chunks.bucket}/*",
                "arn:aws:s3:::${minio_s3_bucket.loki_ruler.bucket}",
                "arn:aws:s3:::${minio_s3_bucket.loki_ruler.bucket}/*",
                "arn:aws:s3:::${minio_s3_bucket.loki_admin.bucket}",
                "arn:aws:s3:::${minio_s3_bucket.loki_admin.bucket}/*"
            ],
            "Sid": ""
        }
    ]
}
EOF
}

resource "minio_iam_user_policy_attachment" "loki_user_rw" {
  user_name   = minio_iam_user.loki.id
  policy_name = minio_iam_policy.loki_rw_policy.id
}
