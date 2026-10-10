# 1. 打包代码
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# 2. 创建 Lambda
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}