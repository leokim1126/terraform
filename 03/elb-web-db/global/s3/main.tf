# 1. provider 생성
# 2. S3 mybucket 생성
# 3. Dynamodb Table 생성 (Lock ID)

# 1. provider 생성
provider "aws" {
  region = "us-east-2"
}

# 2. S3 mybucket 생성
resource "aws_s3_bucket" "mytfstate" {
  bucket = "myysk-0215"

  tags = {
    Name        = "mytfstate"
  }
}

# 3. Dynamodb Table 생성 (Lock ID)
# S3 bucket ARN -> output
# DynamoDB table name -> output
resource "aws_dynamodb_table" "mylocktable" {
  name           = "mylocktable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockId"

  attribute {
    name = "LockId"
    type = "S"
  }

  tags = {
    Name        = "mylocktable"
  }
}
