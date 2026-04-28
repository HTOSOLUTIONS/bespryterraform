resource "aws_cognito_user_pool" "this" {
  name = var.name
  tags = var.tags

  # Match legacy pool
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Optional: SES parity (use your account id)
  email_configuration {
    email_sending_account = "DEVELOPER"
    source_arn            = "arn:aws:ses:us-east-2:891377401485:identity/bespry.net"
    from_email_address    = "noreply@bespry.net"
  }
}


resource "aws_cognito_user_pool_client" "this" {
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Optional: make token durations explicit
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  
  lifecycle {
    ignore_changes = all
  }  
  
}
