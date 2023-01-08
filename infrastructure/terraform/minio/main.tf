# variable "myfile_content" {
#   type        = string
#   description = "Content of myfile.txt for test"
#   default     = "Hello from Terraform."
# }

# resource "local_file" "myfile" {
#   filename = "myfile.txt"
#   content  = var.myfile_content
# }

# output "myfile_id" {
#   value = local_file.myfile.id
# }

# resource "tls_private_key" "my_private_key" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }

# resource "local_file" "private_key" {
#   filename = "id_rsa"
#   content = tls_private_key.my_private_key.private_key_openssh
# }

# resource "local_file" "public_key" {
#   filename = "id_rsa.pub"
#   content = tls_private_key.my_private_key.public_key_openssh
# }

terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "1.10.0"
    }
  }
}
