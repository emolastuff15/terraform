resource "aws_s3_bucket" "this" {
  count  = length(var.bucket_names)
  bucket = var.bucket_names[count.index]

  tags = {
    Name = var.bucket_names[count.index]
  }
}


resource "aws_s3_bucket_ownership_controls" "this" {
  count  = length(var.bucket_names)
  bucket = aws_s3_bucket.this[count.index].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = length(var.bucket_names)
  bucket = aws_s3_bucket.this[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}