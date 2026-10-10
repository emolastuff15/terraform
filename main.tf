provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}


variable "bucket_names" {
  type = list(string)
  default = [
    "mycompany-dev-source1",

  ]
}

module "events" {
  source        = "./module/events"
  bucket_names  = var.bucket_names
  lambda_arn    = module.lambda.lambda_arn
  bucket_arn    = module.storage.bucket_arn
  function_name = module.lambda.lambda_name

}

module "storage" {
  source       = "./module/storage"
  bucket_names = var.bucket_names # ← 关键：把根模块的值赋给模块的输入
}

module "iam" {
  source       = "./module/iam"
  bucket_names = var.bucket_names
}
module "lambda" {
  source        = "./module/lambda"
  function_name = "pdf-metadata-cataloger"
  role_arn      = module.iam.role_arn
}

output "bucket_arn" {
  value = module.storage.bucket_arn
}

output "bucket_arns" {
  value = module.storage.bucket_arns
}
/*
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = {
    Name = var.instance_name
  }
}
*/


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true
}

