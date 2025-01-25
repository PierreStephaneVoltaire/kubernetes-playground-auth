variable "app_name" {
  type    = string
  default = "infra"
}
variable "tags" {
  type = map(string)
}
variable "domain_name" {
  type = string
}

variable "bucket" {
  type = string
}
variable "network_key" {
  type = string
}

variable "users" {
  type = map(object({ email = string }))
}