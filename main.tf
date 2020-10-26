
provider "aws" {
  profile = "linuxAcademy"
  region  = "us-east-1"
}

locals {
  s3_origin_id = "georgi-bucket"
  bucket_name  = "georgi-bucket"
  region       = "us-east-1"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::georgi-bucket/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = "georgi-bucket"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_cloudfront_origin_access_identity" "cf" {
  comment = "playing with terraform"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  origin {
    domain_name = "${local.bucket_name}.s3.${local.region}.amazonaws.com"
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf.cloudfront_access_identity_path
    }
  }

  enabled = true
  comment = "DNA"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/VideoImages/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "allow-all"
  }


  # price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "DEV"
    Service     = "DNA:PE"
    Contact     = "test@email.com"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
