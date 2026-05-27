resource "aws_cognito_user_pool" "support" {
  name = var.user_pool_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 160
    }
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "web" {
  name         = var.app_client_name
  user_pool_id = aws_cognito_user_pool.support.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  supported_identity_providers  = ["COGNITO"]
  access_token_validity         = 60
  id_token_validity             = 60
  refresh_token_validity        = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_user" "admin" {
  count        = var.create_admin_user ? 1 : 0
  user_pool_id = aws_cognito_user_pool.support.id
  username     = var.admin_email

  temporary_password = var.admin_temp_password
  message_action     = "SUPPRESS"

  attributes = {
    email          = var.admin_email
    email_verified = "true"
  }
}

output "user_pool_id" {
  value = aws_cognito_user_pool.support.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.support.arn
}

output "client_id" {
  value = aws_cognito_user_pool_client.web.id
}
