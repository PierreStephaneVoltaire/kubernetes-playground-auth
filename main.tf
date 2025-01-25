terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.8"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "> 1.16.0"

    }
  }
  required_version = ">= 1.3.0"
}

data "aws_region" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key    = var.network_key
    region = data.aws_region.current.name
  }
}
output "cognito_endpoint" {
  value = aws_cognito_user_pool.auth.endpoint
}
output "argo_app_client_id" {
  value = aws_cognito_user_pool_client.auth.id
}
output "argo_app_client_secret" {
  value     = aws_cognito_user_pool_client.auth.client_secret
  sensitive = true
}

output "jenkins_app_client_id" {
  value = aws_cognito_user_pool_client.jenkins_auth.id
}
output "jenkins__app_client_secret" {
  value     = aws_cognito_user_pool_client.jenkins_auth.client_secret
  sensitive = true

}
