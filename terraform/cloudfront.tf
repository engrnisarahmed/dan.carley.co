data "aws_acm_certificate" "website" {
  domain   = "${var.website_name}"
  statuses = ["ISSUED"]
  provider = "aws.us-east"
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = "${aws_s3_bucket.website.website_endpoint}"
    origin_id   = "origin-bucket-${aws_s3_bucket.website.id}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.website_name}"
  default_root_object = "index.html"

  aliases = ["${var.website_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.website.arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }
}
