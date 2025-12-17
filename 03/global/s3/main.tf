# 1. S3 버킷 생성
# 2. dynamodb 생성

# 1. S3 버킷 생성
resource "aws_s3_bucket" "my_tfstate" {
  bucket = "ysk-1206"

  tags = {
    Name        = "ysk-1206"
  }
}

# 2. dynamodb 생성
resource "aws_dynamodb_table" "my_tflocks" {
  name           = "my_tflocks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "my_tflocks"
  }
}