output "bucket_name" {
  description = "S3バケット名"
  value       = aws_s3_bucket.spa.bucket
}

output "bucket_arn" {
  description = "S3バケットARN"
  value       = aws_s3_bucket.spa.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront ディストリビューションID"
  value       = aws_cloudfront_distribution.spa.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront ディストリビューションARN"
  value       = aws_cloudfront_distribution.spa.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront ドメイン名"
  value       = aws_cloudfront_distribution.spa.domain_name
}

output "cloudfront_url" {
  description = "CloudFront URL"
  value       = "https://${aws_cloudfront_distribution.spa.domain_name}"
}
