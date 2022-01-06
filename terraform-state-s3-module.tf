terraform {
  required_version = ">= 1.1.2"
}

provider "aws" {}

variable "terraform_state_bucket_name" {
  type = string
}

variable "terraform_state_table_name" {
  type = string
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket_name
  
  lifecycle {
    prevent_destroy = true
  }
  
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_locks" {
  name           = var.terraform_state_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_state_locks.name
}
