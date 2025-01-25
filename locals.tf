locals {
  domain         = replace(var.domain_name, ".", "")
  argo_domain    = "argocd.${var.domain_name}"
  jenkins_domain = "jenkins.${var.domain_name}"
  vault_domain   = "vault.${var.domain_name}"

}
