resource "tls_private_key" "eb_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload public key to AWS as an EC2 Key Pair
resource "aws_key_pair" "eb_ssh" {
  key_name   = "bespry-eb-dev"
  public_key = tls_private_key.eb_ssh.public_key_openssh

  tags = local.tags
}

# Write private key to disk for MySQL Workbench SSH tunneling
# (DO NOT COMMIT THIS FILE)
resource "local_sensitive_file" "eb_ssh_pem" {
  filename        = "${path.module}\\.keys\\bespry-eb-dev.pem"
  content         = tls_private_key.eb_ssh.private_key_pem
  file_permission = "0600"
}

# Optional: also write .pub for reference
resource "local_file" "eb_ssh_pub" {
  filename = "${path.module}\\.keys\\bespry-eb-dev.pub"
  content  = tls_private_key.eb_ssh.public_key_openssh
}
