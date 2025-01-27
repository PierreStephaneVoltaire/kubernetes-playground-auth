
resource "aws_cognito_user_pool" "auth" {
  name                     = "${var.app_name}-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  schema {
    attribute_data_type = "String"
    name               = "groups"
    developer_only_attribute = false
    required           = false
    mutable            = false
    string_attribute_constraints {}

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
