

resource "aws_cognito_user_pool_client" "auth" {
  name                = "${var.app_name}-client"
  user_pool_id        = aws_cognito_user_pool.auth.id
  generate_secret     = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  callback_urls       = ["https://${local.argo_domain}/auth/callback","https://${local.argo_domain}/api/dex/callback"]
  logout_urls         = ["https://${local.argo_domain}/auth/logout","https://${local.argo_domain}/api/dex/logout"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "profile", "email"]
  supported_identity_providers         = ["COGNITO"]
}
resource "aws_cognito_identity_pool" "argo_identity_pool" {
  identity_pool_name               = "${var.app_name}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    provider_name = aws_cognito_user_pool.auth.endpoint
    client_id     = aws_cognito_user_pool_client.auth.id
  }
}


resource "aws_cognito_user_group" "argo" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.auth.id
  role_arn     = aws_iam_role.argo_authenticated_role.arn
}
resource "aws_cognito_user_group" "argo_readers" {
  user_pool_id = aws_cognito_user_pool.auth.id
  name         = "readonly"
}


resource "aws_iam_role" "argo_authenticated_role" {
  name = "argo_authenticated_role"
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
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.argo_identity_pool.id
          }
        }
      }
    ]
  })
}


resource "aws_cognito_user_in_group" "argo_user_groups" {
  for_each     = aws_cognito_user.user
  user_pool_id = aws_cognito_user_pool.auth.id
  group_name   = aws_cognito_user_group.argo.name
  username     = each.value.username
}

