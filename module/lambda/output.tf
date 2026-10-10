output "lambda_arn"{
  description = "lambda de arn"
  value = aws_lambda_function.this.arn
}

output "lambda_name" {
  value = aws_lambda_function.this.function_name
}