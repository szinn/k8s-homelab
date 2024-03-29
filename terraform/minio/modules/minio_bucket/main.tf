terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
    }
  }
}

resource "minio_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "minio_s3_bucket_policy" "bucket" {
  bucket = minio_s3_bucket.bucket.bucket
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Resource": ["arn:aws:s3:::${minio_s3_bucket.bucket.bucket}"],
      "Action": ["s3:ListBucket"]
    }
  ]
}
EOF
}

resource "minio_iam_user" "user" {
  name          = var.user_name != null ? var.user_name : var.bucket_name
  force_destroy = true
  secret        = var.user_secret != null ? var.user_secret : null
}

resource "minio_iam_policy" "rw_policy" {
  name   = format("%s-private", var.user_name)
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
                "arn:aws:s3:::${minio_s3_bucket.bucket.bucket}",
                "arn:aws:s3:::${minio_s3_bucket.bucket.bucket}/*"
            ],
            "Sid": ""
        }
    ]
}
EOF
}

resource "minio_iam_user_policy_attachment" "user_rw" {
  user_name   = minio_iam_user.user.id
  policy_name = minio_iam_policy.rw_policy.id
}
