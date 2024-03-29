# cloudfront
module "cloudfront" {
  source = "../../../modules/CloudFront"

  # distribution
  origin = [{
    domain_name              = module.origin_s3.s3_bucket.bucket_regional_domain_name
    origin_access_control_id = null
    origin_id                = module.origin_s3.s3_bucket.arn
    origin_path              = null
    custom_origin_config     = null
    custom_header            = null
    origin_shield            = null
    connection_attempts      = 3
    connection_timeout       = 10
    }
  ]

  default_cache_behavior = [{
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = module.origin_s3.s3_bucket.arn
    cache_policy_id            = null
    origin_request_policy_id   = null
    response_headers_policy_id = null
  }]

  /*
  CloudFrontのデフォルトの証明書を利用する場合
    viewer_certificate = [{
      cloudfront_default_certificate = true
      acm_certificate_arn            = null
      minimum_protocol_version       = null
      ssl_support_method             = null
    }]

  ユーザー発行の証明書を利用する場合
    viewer_certificate = [{
      cloudfront_default_certificate = false
      acm_certificate_arn            = data.terraform_remote_state.acm_us_east_1.outputs.acm_certificate_validation_certificate_us_east_1.aws_acm_certificate_validation_certificate_arn
      minimum_protocol_version       = "TLSv1.2_2021"
      ssl_support_method             = "sni-only"
    }]
  */

  aliases = ["cf.yuki-m.com"]

  viewer_certificate = [{
    cloudfront_default_certificate = false
    acm_certificate_arn            = data.terraform_remote_state.acm_us_east_1.outputs.acm_certificate_validation_certificate_us_east_1.aws_acm_certificate_validation_certificate_arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }]

  # oac
  oac_create  = true
  oac_name    = "CloudFront-OAC"
  description = "test CloudFront-OAC"

}


# S3
module "origin_s3" {
  source = "../../../modules/S3"

  # bucket
  bucket_name          = "test-ymitsuyama-origin-s3bucket"
  bucket_force_destroy = true

  # ownership_controls
  object_ownership = "BucketOwnerPreferred"

  # versionings
  versioning_status = "Enabled"

  # s3_bucket_policy
  create_bucket_policy   = true
  bucket_policy_document = data.aws_iam_policy_document.static-www.json
}

# s3_object
resource "aws_s3_object" "object" {
  bucket       = module.origin_s3.s3_bucket.id
  key          = "index.html"
  source       = "${path.root}/source/index.html"
  etag         = filemd5("${path.root}/source/index.html")
  content_type = "text/html"
}


module "route53_cloudfront_record" {
  source = "../../../modules/Route53"

  create_record = true
  zone_id       = data.aws_route53_zone.main.zone_id
  record_name   = "cf.yuki-m.com"
  type          = "A"
  alias = [{
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = module.cloudfront.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }]
}
