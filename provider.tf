terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  #   backend "s3" {
  #     bucket         = "dev-three-tier-web-state"
  #     key            = "devops-test/terraform.tfstate"
  #     region         = "eu-west-1"
  #     dynamodb_table = "dev-terraform-locks"
  #     encrypt        = true
  #   }
}

provider "aws" {
  region = "eu-west-1"
}
