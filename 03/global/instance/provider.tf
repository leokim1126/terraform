terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }

   backend "s3" {
    bucket = "ysk-1206"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "my_tflcoks"
  }
}

provider "aws" {
  region = "us-east-2"
}