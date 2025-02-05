resource "aws_cognito_user_pool_client" "auth" {
  name            = "${var.app_name}-client"
  user_pool_id    = aws_cognito_user_pool.auth.id
  generate_secret = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  callback_urls = ["https://${local.argo_domain}/auth/callback", "https://${local.argo_domain}/api/dex/callback"]
  logout_urls   = ["https://${local.argo_domain}/auth/logout", "https://${local.argo_domain}/api/dex/logout","https://${local.argo_domain}/applications"]
  access_token_validity  = 15
  id_token_validity      = 15
  refresh_token_validity = 60

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "minutes"
  }
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
resource "aws_cognito_user_pool_client" "jenkins_auth" {
  name                                 = "${var.app_name}-jenkins-client"
  user_pool_id                         = aws_cognito_user_pool.auth.id
  generate_secret                      = true
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  callback_urls                        = ["https://${local.jenkins_domain}/auth/callback"]
  logout_urls                          = ["https://${local.jenkins_domain}/auth/logout"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "phone", "openid"]
  supported_identity_providers         = ["COGNITO"]
}
resource "aws_cognito_identity_pool" "jenkins_identity_pool" {
  identity_pool_name               = "${var.app_name}-jenkins-identity-pool"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    provider_name = aws_cognito_user_pool.auth.endpoint
    client_id     = aws_cognito_user_pool_client.jenkins_auth.id
  }
}


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


