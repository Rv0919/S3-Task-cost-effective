provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAV47KEOYMTZN2SAXT"
  secret_key = "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"
}


#  S3 bucket for data storage
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-task0919"
}

#  S3 Intelligent-Tiering for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "intelligent_tiering" {
  rule {
    id      = "intelligent_tiering_rule"
    status  = "Enabled"

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  bucket = aws_s3_bucket.my_bucket.id
}

#  S3 Transfer Acceleration for faster data transfer
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# S3 Glacier lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "glacier_lifecycle" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "glacier_transition"
    status = "Enabled"

    filter {
      prefix = "my_s3glacier"  # Replace "your-prefix" with your desired prefix
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}


#  CloudFront distribution to serve content from the S3 bucket
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"
  }

  enabled = true

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods       = ["GET", "HEAD", "OPTIONS"]
    cached_methods        = ["GET", "HEAD", "OPTIONS"]
    target_origin_id      = "S3Origin"  # This line is important
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  #  default CloudFront certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}
