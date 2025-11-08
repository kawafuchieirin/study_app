variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "環境名（dev, prod）"
  type        = string
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "study-app"
}

variable "component_name" {
  description = "コンポーネント名"
  type        = string
  default     = "frontend"
}

variable "cloudfront_price_class" {
  description = "CloudFront Price Class"
  type        = string
  default     = "PriceClass_200"
}
