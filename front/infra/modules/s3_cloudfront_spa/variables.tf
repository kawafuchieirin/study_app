variable "bucket_name" {
  description = "S3バケット名（グローバルで一意である必要がある）"
  type        = string
}

variable "price_class" {
  description = "CloudFront の価格クラス"
  type        = string
  default     = "PriceClass_200" # アジア、ヨーロッパ、北米
}

variable "comment" {
  description = "CloudFront distribution のコメント"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM証明書のARN（カスタムドメイン使用時）"
  type        = string
  default     = null
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
