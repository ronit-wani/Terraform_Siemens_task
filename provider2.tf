terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "4.67.0"
    }
  }
  backend "s3" {
      bucket         = "lb_logs"
      key            = "global/s3/tf-state/terraform.tfstate"
      region         = "eu-west-1"
      dynamodb_table = "dynamodb1"
      encrypt        = true
  }
  
}


provider "aws" {
  region = var.region
  profile = "default"
}
