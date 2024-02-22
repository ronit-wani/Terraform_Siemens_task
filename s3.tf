# Configure an S3 bucket resource to hold application state files
resource "aws_s3_bucket" "terraform_state" {
  bucket = "<ENTER-A-GLOBALLY-UNIQUE-BUCKET-NAME-HERE>"  
}

# Add bucket versioning for state rollback
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add bucket encryption to hide sensitive state data
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
