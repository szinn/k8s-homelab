terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
    }
  }
}

resource "minio_s3_bucket" "bucket" {
  for_each = toset(var.bucket_names)
  bucket   = each.key
  acl      = "private"
}

resource "minio_s3_bucket_policy" "bucket" {
  for_each = toset(var.bucket_names)
  bucket   = each.key
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Resource": ["arn:aws:s3:::${each.key}"],
      "Action": ["s3:ListBucket"]
    }
  ]
}
EOF
}

resource "minio_iam_user" "user" {
  name          = var.user_name
  force_destroy = true
  secret        = var.user_secret
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
                %{for i, bucket in var.bucket_names}
                "arn:aws:s3:::${bucket}",
                "arn:aws:s3:::${bucket}/*"
                %{if i < length(var.bucket_names) - 1}
                ,
                %{endif}
                %{endfor}
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
