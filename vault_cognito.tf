

resource "aws_cognito_user_pool_client" "vault_auth" {
  name            = "${var.app_name}-vault-client"
  user_pool_id    = aws_cognito_user_pool.auth.id
  generate_secret = true
  callback_urls   = ["https://${local.vault_domain}/oidc/callback", "https://${local.vault_domain}/ui/vault/auth/oidc/oidc/callback"]
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
}
resource "aws_cognito_identity_pool" "vault_identity_pool" {
  identity_pool_name               = "${var.app_name}-vault-identity-pool"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    provider_name = aws_cognito_user_pool.auth.endpoint
    client_id     = aws_cognito_user_pool_client.vault_auth.id
  }
}
resource "aws_cognito_user_group" "vault" {
  name         = "${var.app_name}-vault-group"
  user_pool_id = aws_cognito_user_pool.auth.id
  role_arn     = aws_iam_role.vault_authenticated_role.arn
}
resource "aws_iam_role" "vault_authenticated_role" {
  name = "vault_authenticated_role"
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
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.vault_identity_pool.id
          }
        }
      }
    ]
  })
}



resource "aws_cognito_user_in_group" "vault_user_groups" {
  for_each     = aws_cognito_user.user
  user_pool_id = aws_cognito_user_pool.auth.id
  group_name   = aws_cognito_user_group.vault.name
  username     = each.value.username
}

