# GitHub Actions Deployment Guide for Certificate Integration

## 🚀 **ACM Certificate Module Integration Complete**

The demo environment is now configured with the ACM certificate module and ready for GitHub Actions deployment.

## 📋 **Current Configuration Status**

### ✅ **What's Configured:**
- **ACM Certificate Module**: Integrated into demo environment
- **US-East-1 Provider**: Added for ACM certificate requirements
- **Domain Variables**: Added to `terraform.tfvars` (disabled by default)
- **Certificate Outputs**: Available for GitHub Actions discovery
- **Terraform Formatting**: All files properly formatted

### 🔧 **Demo Environment Setup:**
```
terraform/environments/demo/
├── main.tf           # Includes ACM certificate module
├── variables.tf      # Domain configuration variables
├── outputs.tf        # Certificate ARN and domain outputs
└── terraform.tfvars  # Domain settings (disabled by default)
```

## 🎯 **GitHub Actions Deployment Options**

### **Option 1: Deploy Without Custom Domain (Current Default)**
```bash
# Current terraform.tfvars settings:
enable_custom_domain = false
domain_name          = ""
host_name            = ""
```

**Result**: 
- EKS cluster deploys normally
- No certificate provisioned
- Application accessible via ALB DNS name
- GitHub Actions workflow discovers no certificates (expected)

### **Option 2: Deploy With Custom Domain**
Update `terraform.tfvars`:
```hcl
enable_custom_domain = true
domain_name          = "k8sdemo.click"
host_name            = "sedaro"
include_wildcard     = false
```

**Result**:
- EKS cluster + ACM certificate provisioned
- Certificate validated via Route53 DNS
- GitHub Actions discovers certificate ARN
- Application accessible via `https://sedaro.k8sdemo.click`

## 🔄 **GitHub Actions Workflow Integration**

### **Current Workflow Compatibility**
Your existing `.github/workflows/deploy-k8s.yml` is **already compatible**:

1. **Certificate Discovery** (when domain enabled):
   ```bash
   aws acm list-certificates --region us-east-1 \
     --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn" \
     --output text
   ```

2. **Terraform Outputs** (available after infrastructure deployment):
   ```bash
   # GitHub Actions can access these outputs:
   terraform output certificate_arn
   terraform output certificate_domain
   terraform output certificate_status
   ```

3. **Helm Deployment** (works with or without domain):
   - Without domain: Uses default ALB configuration
   - With domain: Uses discovered certificate ARN and TLS configuration

## 🎮 **Deployment Commands for GitHub Actions**

### **Infrastructure Deployment (Terraform)**
```bash
# GitHub Actions will run:
cd terraform/environments/demo
terraform init
terraform plan
terraform apply -auto-approve
```

### **Application Deployment (Helm)**
```bash
# With domain enabled, GitHub Actions will run:
helm upgrade --install sedaro-nano ./helm/sedaro-nano \
  --set domain.enabled=true \
  --set domain.name="k8sdemo.click" \
  --set domain.host="sedaro" \
  --set tls.enabled=true \
  --set tls.certificate.arn="arn:aws:acm:us-east-1:...:certificate/..." \
  --wait
```

## 🛡️ **Security and Access**

### **Required GitHub Repository Variables**
For certificate deployment, ensure these are set:
- `DOMAIN`: `k8sdemo.click` (to enable domain configuration)
- `HOST`: `sedaro` (subdomain prefix)

### **AWS Permissions**
Your GitHub Actions role needs these additional permissions:
- `acm:ListCertificates`
- `acm:DescribeCertificate`
- `acm:RequestCertificate`
- `route53:ChangeResourceRecordSets`
- `route53:GetHostedZone`

## 📊 **Deployment Timeline**

1. **Terraform Apply** (5-8 minutes):
   - EKS cluster creation
   - ACM certificate request
   - DNS validation (1-2 minutes)
   - Certificate validation completion

2. **Helm Deployment** (2-3 minutes):
   - Certificate ARN discovery
   - Ingress with TLS configuration
   - Application pods deployment

**Total**: ~10 minutes for complete infrastructure + application deployment

## ✅ **Validation After Deployment**

GitHub Actions can validate the deployment:
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1

# Check ingress configuration
kubectl get ingress -n default

# Verify HTTPS access
curl -I https://sedaro.k8sdemo.click/health
```

## 🚀 **Next Steps**

1. **Ready for Deployment**: Configuration is complete and formatted
2. **Choose Deployment Mode**: 
   - Keep `enable_custom_domain = false` for ALB-only deployment
   - Set `enable_custom_domain = true` for full HTTPS with custom domain
3. **Run GitHub Actions**: Push changes to trigger deployment
4. **Monitor Deployment**: Watch GitHub Actions logs for certificate provisioning

Your certificate integration is **production-ready** and fully automated through GitHub Actions! 🎉
