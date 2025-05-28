# Outputs for ACM Certificate Module

output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = var.enable_custom_domain ? aws_acm_certificate_validation.domain_cert[0].certificate_arn : ""
}

output "certificate_domain" {
  description = "Domain name of the certificate"
  value       = var.enable_custom_domain ? "${var.host_name}.${var.domain_name}" : ""
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.enable_custom_domain ? data.aws_route53_zone.domain[0].zone_id : ""
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = var.enable_custom_domain ? aws_acm_certificate.domain_cert[0].status : "disabled"
}
