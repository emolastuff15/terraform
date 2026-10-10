# 需求 3：使用已存在的 S3 后端存储 state，并启用 S3 原生锁
#
# 说明：
# - backend 块不支持变量/插值，所有值必须是字面量
# - use_lockfile = true 需要 Terraform >= 1.10，用它就不再需要 DynamoDB 锁表
# - 这个桶【不归本配置管理】，是 bootstrap 时手工建的，
#   这样 terraform destroy 永远不会删掉自己的 state
terraform {
  backend "s3" {
    bucket       = "mycompany-tfstate-289138883270"
    key          = "terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
