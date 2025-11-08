# Frontend outputs
output "frontend_bucket_name" {
  description = "Frontend S3バケット名"
  value       = module.frontend.bucket_name
}

output "frontend_cloudfront_url" {
  description = "Frontend CloudFront URL"
  value       = module.frontend.cloudfront_url
}

output "frontend_cloudfront_distribution_id" {
  description = "Frontend CloudFront ディストリビューションID"
  value       = module.frontend.cloudfront_distribution_id
}
