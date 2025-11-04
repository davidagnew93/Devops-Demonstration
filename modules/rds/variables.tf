variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "common_tags" {
  type = map(string)
}

variable "allowed_security_groups" {
  type = list(string)
}

variable "project" {
  type    = string
  default = "scalable-web-stack"
}

variable "environment" {
  type    = string
  default = "dev"
}
