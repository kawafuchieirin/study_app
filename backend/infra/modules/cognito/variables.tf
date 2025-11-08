variable "user_pool_name" {
  description = "Cognito User Pool名"
  type        = string
}

variable "app_client_name" {
  description = "Cognito App Client名"
  type        = string
}

variable "domain_prefix" {
  description = "Cognito Domain Prefix"
  type        = string
}

variable "callback_urls" {
  description = "コールバックURL"
  type        = list(string)
}

variable "logout_urls" {
  description = "ログアウトURL"
  type        = list(string)
}

variable "tags" {
  description = "リソースタグ"
  type        = map(string)
  default     = {}
}
