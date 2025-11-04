variable "common_tags" {
  type = map(string)
}

variable "project" {
  type    = string
  default = "scalable-web-stack"
}

variable "environment" {
  type    = string
  default = "dev"
}
