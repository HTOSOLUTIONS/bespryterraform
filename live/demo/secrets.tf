resource "aws_secretsmanager_secret" "bespry_config" {
  name = "bespry/${var.env}/config"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "bespry_config_current" {
  secret_id = aws_secretsmanager_secret.bespry_config.id

  secret_string = jsonencode({
    host     = module.db.endpoint
    dbname   = module.db.db_name
    username = var.db_username
    password = var.db_password
    port     = tostring(module.db.port)
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
