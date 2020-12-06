resource "aws_s3_bucket" "s3_logs_bucket" {
  bucket = var.logs_bucket_name
  versioning {
    enabled = false
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  force_destroy = true
  tags = {
    Owners  : "${var.owner}"
  }
}

resource "aws_s3_bucket" "s3_data_bucket" {
  bucket = var.data_bucket_name
  versioning {
    enabled = false
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  force_destroy = true
  tags = {
    Owners  : "${var.owner}"
  }
}