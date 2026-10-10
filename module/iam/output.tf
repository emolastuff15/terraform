output "role_arn" {
  description = "lambda-s3-metadata 策略的 ARN"
  value       = aws_iam_role.test_role.arn
}
