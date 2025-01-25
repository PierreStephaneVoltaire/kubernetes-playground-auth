

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
resource "aws_cognito_user_group" "jenkins" {
  name         = "${var.app_name}-jenkins-group"
  user_pool_id = aws_cognito_user_pool.auth.id
  role_arn     = aws_iam_role.jenkins_authenticated_role.arn
}
resource "aws_iam_role" "jenkins_authenticated_role" {
  name = "jenkins_authenticated_role"
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
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.jenkins_identity_pool.id
          }
        }
      }
    ]
  })
}
resource "random_password" "jenkins_password" {
  for_each    = var.users
  length      = 12
  min_special = 4
  special     = true
  numeric     = true
  min_numeric = 2
}


resource "aws_cognito_user_in_group" "jenkins_user_groups" {
  for_each     = aws_cognito_user.user
  user_pool_id = aws_cognito_user_pool.auth.id
  group_name   = aws_cognito_user_group.jenkins.name
  username     = each.value.username
}

