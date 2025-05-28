# Sedaro Nano Domain Configuration - Setup & Validation Guide

## Quick Setup Checklist

### Prerequisites ✅
- [ ] AWS Account with EKS cluster deployed
- [ ] Route53 hosted zone for your domain
- [ ] AWS Load Balancer Controller installed in EKS cluster
- [ ] GitHub repository with appropriate AWS IAM role configured

### 1. Domain Configuration Steps

#### A. Repository Variables Setup
1. Go to your GitHub repository
2. Navigate to `Settings > Secrets and variables > Actions > Variables`
3. Add the following repository variables:

| Variable | Value | Example |
|----------|-------|---------|
| `DOMAIN` | Your Route53 domain | `mycompany.com` |
| `HOST` | Subdomain for the app | `sedaro` |

**Result**: App will be accessible at `https://sedaro.mycompany.com`

#### B. SSL Certificate Options

**Option 1: AWS Certificate Manager (Recommended)**
1. Go to AWS Certificate Manager in the `us-east-1` region
2. Request a new certificate for your domain:
   - Domain names: `sedaro.mycompany.com` OR `*.mycompany.com`
   - Validation method: DNS validation
3. Add the CNAME records to your Route53 hosted zone
4. Wait for certificate validation (usually 5-30 minutes)

**Option 2: cert-manager with Let's Encrypt**
- No manual setup required
- Automatic certificate provisioning
- Set `tls.certificate.useCertManager=true` in values if needed

### 2. Deployment

#### Automatic Deployment (Recommended)
1. Push code to main branch or manually trigger workflow
2. GitHub Actions will:
   - Auto-detect ACM certificates
   - Configure domain settings
   - Deploy with HTTPS enabled

#### Manual Deployment
```bash
# Set your values
DOMAIN="mycompany.com"
HOST="sedaro"
FULL_DOMAIN="${HOST}.${DOMAIN}"
ECR_REGISTRY="your-account.dkr.ecr.us-east-1.amazonaws.com"

# Find ACM certificate (optional)
CERT_ARN=$(aws acm list-certificates \
  --region us-east-1 \
  --query "CertificateSummaryList[?DomainName=='${FULL_DOMAIN}' || contains(SubjectAlternativeNameSummary, '${FULL_DOMAIN}') || DomainName=='*.${DOMAIN}'].CertificateArn" \
  --output text | head -1)

# Deploy with Helm
helm upgrade --install sedaro-nano oci://${ECR_REGISTRY}/helm-charts/sedaro-nano \
  --version latest \
  --namespace sedaro-nano \
  --create-namespace \
  --set image.backendRepository="${ECR_REGISTRY}/sedaro-nano-demo-backend" \
  --set image.frontendRepository="${ECR_REGISTRY}/sedaro-nano-demo-frontend" \
  --set image.tag="latest" \
  --set domain.enabled=true \
  --set domain.name="${DOMAIN}" \
  --set domain.host="${HOST}" \
  --set domain.fullName="${FULL_DOMAIN}" \
  --set tls.enabled=true \
  --set tls.certificate.arn="${CERT_ARN}" \
  --wait --timeout 10m
```

### 3. DNS Configuration

After deployment, configure your Route53 hosted zone:

1. Get the ALB hostname:
```bash
kubectl get ingress sedaro-nano -n sedaro-nano -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Create a CNAME record in Route53:
   - **Name**: `sedaro` (or your HOST value)
   - **Type**: `CNAME`
   - **Value**: `<ALB-hostname-from-step-1>`
   - **TTL**: `300`

### 4. Validation

#### Run Test Script
```powershell
# Basic template validation
.\scripts\test-domain-config.ps1 -TestMode template

# Full validation with dry-run
.\scripts\test-domain-config.ps1 -TestMode dry-run -Domain "mycompany.com" -Host "sedaro"
```

#### Manual Verification
```bash
# Check deployment status
kubectl get all -n sedaro-nano

# Check ingress configuration
kubectl describe ingress sedaro-nano -n sedaro-nano

# Check TLS certificate
kubectl get secret -n sedaro-nano

# Test application access
curl -I https://sedaro.mycompany.com/health.html
```

## Troubleshooting Guide

### Common Issues

#### 1. Certificate Not Found
**Symptom**: "No ACM certificate found" in logs
**Solution**:
- Verify certificate exists in `us-east-1` region
- Check certificate domain matches exactly or uses wildcard
- Ensure certificate status is "Issued"

#### 2. DNS Resolution Issues
**Symptom**: Domain not resolving
**Solution**:
- Verify CNAME record in Route53
- Check TTL and wait for propagation
- Test with `nslookup sedaro.mycompany.com`

#### 3. ALB Not Responding
**Symptom**: Connection timeouts
**Solution**:
- Check ALB target groups in AWS console
- Verify security group rules
- Check EKS node connectivity

#### 4. TLS/SSL Issues
**Symptom**: Certificate warnings or HTTP instead of HTTPS
**Solution**:
- Verify certificate ARN is correct
- Check ALB listener configuration
- Validate certificate domain coverage

### Debug Commands

```bash
# Check ALB configuration
aws elbv2 describe-load-balancers --region us-east-1

# Check ACM certificates
aws acm list-certificates --region us-east-1

# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id YOUR_ZONE_ID

# Test SSL certificate
openssl s_client -connect sedaro.mycompany.com:443 -servername sedaro.mycompany.com

# Check Kubernetes events
kubectl get events -n sedaro-nano --sort-by='.lastTimestamp'

# Check ingress controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Configuration Reference

### GitHub Repository Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DOMAIN` | Yes* | Your Route53 domain name | `mycompany.com` |
| `HOST` | Yes* | Subdomain/hostname | `sedaro` |

*Required for domain functionality

### Helm Values Override

For advanced configuration, create a custom values file:

```yaml
# custom-values.yaml
domain:
  enabled: true
  name: "mycompany.com"
  host: "sedaro"
  fullName: "sedaro.mycompany.com"

tls:
  enabled: true
  certificate:
    useACM: true
    arn: "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-..."
  redirect:
    enabled: true
    statusCode: "HTTP_301"

ingress:
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: "sedaro-nano-custom"
    alb.ingress.kubernetes.io/tags: "Environment=production,Project=sedaro-nano"
```

Deploy with custom values:
```bash
helm upgrade --install sedaro-nano oci://${ECR_REGISTRY}/helm-charts/sedaro-nano \
  --values custom-values.yaml \
  # ... other parameters
```

## Security Considerations

1. **Certificate Management**: Use ACM for automatic renewal
2. **HTTPS Enforcement**: SSL redirect is enabled by default
3. **Security Groups**: Ensure proper ingress rules for ALB
4. **IAM Permissions**: Minimal permissions for GitHub Actions role
5. **Monitoring**: Set up CloudWatch alarms for ALB health

## Next Steps

1. **Monitoring Setup**: Configure application monitoring and alerts
2. **Backup Strategy**: Implement backup procedures for persistent data
3. **Scaling**: Configure HPA based on application metrics
4. **Security**: Regular security audits and updates
5. **CI/CD**: Enhance pipeline with additional environments (staging, prod)
