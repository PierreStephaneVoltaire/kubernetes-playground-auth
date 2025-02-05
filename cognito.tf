resource "aws_cognito_user_pool" "auth" {
  name                     = "${var.app_name}-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  schema {
    attribute_data_type      = "String"
    name                     = "groups"
    developer_only_attribute = false
    required                 = false
    mutable                  = false
    string_attribute_constraints {}

  }
lambda_config {
  pre_sign_up = aws_lambda_function.cognito_post_signup.arn
}
}

resource "random_password" "user_password" {
  for_each    = var.users
  length      = 12
  min_special = 4
  special     = true
  numeric     = true
  min_numeric = 2
  min_lower   = 1
  min_upper   = 1
}
resource "aws_cognito_user" "user" {
  for_each       = var.users
  user_pool_id   = aws_cognito_user_pool.auth.id
  username       = each.value.email
  password       = random_password.user_password[each.key].result
  message_action = "SUPPRESS"
  attributes = {
    email          = each.value.email
    email_verified = true
  }
}
resource "aws_kms_key" "creds" {
  deletion_window_in_days = 7
}
resource "aws_ssm_parameter" "creds" {
  for_each = aws_cognito_user.user
  name     = "/${var.app_name}/cognito-users/${each.key}"
  type     = "SecureString"
  key_id   = aws_kms_key.creds.key_id
  value    = jsonencode({ username : each.value.username, password : each.value.password, pool_id : each.value.user_pool_id })
}
resource "aws_iam_role" "authenticated_role" {
  name = "authenticated_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = [aws_cognito_identity_pool.argo_identity_pool.id, aws_cognito_identity_pool.vault_identity_pool.id, aws_cognito_identity_pool.jenkins_identity_pool.id]
          }
        }
      }
    ]
  })
}
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.auth.id
  role_arn     = aws_iam_role.authenticated_role.arn

}
resource "aws_cognito_user_group" "readonly" {
  user_pool_id = aws_cognito_user_pool.auth.id
  name         = "readonly"
  role_arn     = aws_iam_role.authenticated_role.arn
}
resource "aws_cognito_user_in_group" "user_groups" {
  for_each     = aws_cognito_user.user
  user_pool_id = aws_cognito_user_pool.auth.id
  group_name   = aws_cognito_user_group.admin.name
  username     = each.value.username
}

