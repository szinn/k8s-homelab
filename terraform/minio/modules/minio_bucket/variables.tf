variable "bucket_names" {
  type    = list(string)
  default = []
}

variable "user_name" {
  type      = string
  sensitive = false
}

variable "user_secret" {
  type      = string
  sensitive = true
}
