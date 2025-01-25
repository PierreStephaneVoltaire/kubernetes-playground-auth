
resource "aws_cognito_user_pool_domain" "auth" {
  domain       = local.domain
  user_pool_id = aws_cognito_user_pool.auth.id
}

