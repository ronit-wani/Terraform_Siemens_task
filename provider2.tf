terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "4.67.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "<ENTER-YOUR-BUCKET-NAME-HERE>"
    key            = "global/s3/tf-state/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "<ENTER-YOUR-DYNAMODB-NAME-HERE>"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
