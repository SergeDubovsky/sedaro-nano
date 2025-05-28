# ACM Certificate Module

This module provisions SSL/TLS certificates using AWS Certificate Manager (ACM) for custom domains in the Sedaro Nano application.

## Features

- 🔒 **Automatic SSL/TLS Certificate Provisioning** using AWS ACM
- 🌐 **DNS Validation** via Route53 integration
- ⚡ **Fast Certificate Validation** (typically 1-2 minutes)
- 🏷️ **Consistent Resource Tagging**
- 🔄 **Lifecycle Management** with proper dependency handling
- 🎯 **US-East-1 Region** optimized for ALB/CloudFront usage

## Usage

```hcl
module "acm_certificate" {
  source = "./modules/acm-certificate"
  
  enable_custom_domain = true
  domain_name         = "k8sdemo.click"
  host_name           = "sedaro"
  environment         = "prod"
  project_name        = "sedaro-nano"
  include_wildcard    = false
  
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
```

## Requirements

- AWS Route53 hosted zone for the domain
- AWS provider configured for us-east-1 region
- Terraform >= 1.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_custom_domain | Enable custom domain and certificate provisioning | `bool` | `false` | no |
| domain_name | The domain name (e.g., k8sdemo.click) | `string` | `""` | yes* |
| host_name | The hostname prefix (e.g., sedaro) | `string` | `""` | yes* |
| environment | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| project_name | Project name for resource tagging | `string` | `"sedaro-nano"` | no |
| include_wildcard | Include wildcard certificate for subdomains | `bool` | `false` | no |

*Required when `enable_custom_domain = true`

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ARN of the validated ACM certificate |
| certificate_domain | Domain name of the certificate |
| route53_zone_id | Route53 hosted zone ID |
| certificate_status | Status of the certificate |

## Certificate Validation

The module automatically:
1. Creates an ACM certificate request
2. Adds DNS validation records to Route53
3. Waits for validation to complete (up to 10 minutes)
4. Returns the validated certificate ARN

## Integration with GitHub Actions

The certificate ARN can be automatically discovered by your GitHub Actions workflow:

```bash
# Your GitHub Actions will find this certificate
aws acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[?DomainName=='sedaro.k8sdemo.click'].CertificateArn" \
  --output text
```

## Resource Tags

All resources are tagged with:
- `Name`: `{project_name}-{environment}-cert`
- `Domain`: `{host_name}.{domain_name}`
- `Environment`: `{environment}`
- `ManagedBy`: `terraform`
