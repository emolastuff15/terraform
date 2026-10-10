# 1. 打包代码
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# 2. 创建 Lambda
resource "aws_lambda_function" "this" {
  function_name = "pdf-metadata-cataloger" # ← 你定
  role          = var.role_arn             # ← 引用角色
  handler       = "lambda.lambda_handler"  # ← 你定
  runtime       = "python3.12"             # ← 你定

  filename         = data.archive_file.lambda_zip.output_path         # ← 数据源
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 # ← 数据源
}