output "bucket_arn" {
  description = "第一个桶的 ARN"
  value       = aws_s3_bucket.this[0].arn
}

output "bucket_arns" {
  description = "所有桶的 ARN 列表"
  value       = aws_s3_bucket.this[*].arn
}

output "bucket_ids" {
  description = "所有桶的 ID（桶名）"
  value       = aws_s3_bucket.this[*].id
}