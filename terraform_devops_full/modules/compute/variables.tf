variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "alb_target_group_arn" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "asg_min_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
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
