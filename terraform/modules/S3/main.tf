resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = lower("${var.project_name}-${var.environment}-web-${random_id.bucket_suffix.hex}")

  mime_types = {
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
  }

  website_files = [
    for file in fileset(var.website_source_dir, "**/*") : file
    if file != "api-config.js"
  ]
}

resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

resource "aws_s3_object" "website_files" {
  for_each = toset(local.website_files)

  bucket       = aws_s3_bucket.website.id
  key          = each.value
  source       = "${var.website_source_dir}/${each.value}"
  etag         = filemd5("${var.website_source_dir}/${each.value}")
  content_type = lookup(local.mime_types, lower(regex("\\.[^.]+$", each.value)), "application/octet-stream")

  depends_on = [
    aws_s3_bucket_policy.allow_public_read,
    aws_s3_bucket_website_configuration.website
  ]
}

resource "aws_s3_object" "api_config" {
  bucket = aws_s3_bucket.website.id
  key    = "api-config.js"

  content_type = "application/javascript; charset=utf-8"
  content = templatefile("${path.module}/api-config.js.tftpl", {
    api_base_url         = var.api_base_url
    cognito_region       = var.cognito_region
    cognito_user_pool_id = var.cognito_user_pool_id
    cognito_client_id    = var.cognito_client_id
  })

  depends_on = [
    aws_s3_bucket_policy.allow_public_read,
    aws_s3_bucket_website_configuration.website
  ]
}

output "bucket_name" {
  value = aws_s3_bucket.website.id
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}
