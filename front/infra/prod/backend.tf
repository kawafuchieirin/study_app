# Terraform backend 設定（prod環境）
#
# 初回セットアップ:
# 1. S3バケットを手動で作成
#    - S3バケット: study-app-front-tfstate-prod
#    - バージョニング有効化推奨
#
# 2. terraform init を実行
#    terraform init

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state設定（S3のみ）
  backend "s3" {
    bucket  = "study-app-front-tfstate-prod"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

# プロバイダー設定
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "study-app"
      Component   = "frontend"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
