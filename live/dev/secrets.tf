resource "aws_secretsmanager_secret" "bespry_config" {
  name = "bespry/${var.env}/config"

  tags = local.tags
}

locals {
  # "foo.rds.amazonaws.com:3306" -> "foo.rds.amazonaws.com"
  db_host = split(":", module.db.endpoint)[0]
}

resource "aws_secretsmanager_secret_version" "bespry_config_current" {
  secret_id = aws_secretsmanager_secret.bespry_config.id

  secret_string = jsonencode({
    host     = local.db_host
    port     = tostring(module.db.port)
    dbname   = module.db.db_name
    username = var.db_username
    password = var.db_password
  })
}


data "aws_iam_policy_document" "api_secrets_read" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.bespry_config.arn]
  }
}

resource "aws_iam_role_policy" "api_secrets_read" {
  name   = "bespry-${var.env}-secrets-read"
  role   = aws_iam_role.api_ec2_role.id
  policy = data.aws_iam_policy_document.api_secrets_read.json
}
