terraform {
  cloud {
    organization = "magized"

    workspaces {
      name = "homelab-minio"
    }
  }
}
