variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "David"
}

variable "project" {
  type    = string
  default = "scalable-web-stack"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 3
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

# Optional ACM certificate ARN for HTTPS on ALB.
# If empty, ALB will remain HTTP only.
variable "acm_certificate_arn" {
  type    = string
  default = ""
}

variable "common_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "devops-test"
    Project     = "scalable-web-stack"
  }
}