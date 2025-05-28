# Certificate Management Module for Sedaro Nano
# This module handles SSL/TLS certificate provisioning for custom domains

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to get existing Route53 hosted zone
data "aws_route53_zone" "domain" {
  count = var.enable_custom_domain ? 1 : 0
  name  = var.domain_name
}

# Request ACM certificate for the domain
resource "aws_acm_certificate" "domain_cert" {
  count = var.enable_custom_domain ? 1 : 0

  domain_name               = "${var.host_name}.${var.domain_name}"
  subject_alternative_names = var.include_wildcard ? ["*.${var.domain_name}"] : []
  validation_method         = "DNS"

  # Certificate should be created in us-east-1 for ALB usage
  provider = aws.us_east_1

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cert"
    Domain      = "${var.host_name}.${var.domain_name}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Create DNS validation records in Route53
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_custom_domain ? {
    for dvo in aws_acm_certificate.domain_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain[0].zone_id
}

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "domain_cert" {
  count = var.enable_custom_domain ? 1 : 0

  certificate_arn         = aws_acm_certificate.domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  provider = aws.us_east_1

  timeouts {
    create = "10m"
  }
}
