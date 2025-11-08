# Frontend（S3 + CloudFront + OAC）

module "frontend" {
  source = "../modules/s3_cloudfront_spa"

  bucket_name = "${var.project_name}-front-${var.environment}"
  price_class = var.cloudfront_price_class
  comment     = "Study App Frontend - ${title(var.environment)} Environment"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = var.component_name
  }
}
