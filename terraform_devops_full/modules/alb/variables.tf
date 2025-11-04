variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

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

variable "acm_certificate_arn" {
  type    = string
  default = ""
}
