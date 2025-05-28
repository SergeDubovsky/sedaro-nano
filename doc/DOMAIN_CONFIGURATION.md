# Custom Domain Configuration with TLS Support

This documentation describes the enhanced pipeline that supports custom domain configuration using Route53 domains with automatic TLS/SSL certificate management.

## Overview

The Sedaro Nano application now supports:
- **Custom Domain Configuration**: Use your own Route53 domain instead of AWS ALB generated URLs
- **Automatic TLS/SSL**: HTTPS configuration with AWS Certificate Manager (ACM) integration
- **Conditional Deployment**: Domain features enabled via GitHub repository variables
- **Certificate Discovery**: Automatic detection of existing ACM certificates

## Configuration

### GitHub Repository Variables

Set these variables in your GitHub repository settings (`Settings > Secrets and variables > Actions > Variables`):

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `DOMAIN` | Your Route53 domain name | `example.com` | Yes (for domain support) |
| `HOST` | Subdomain/hostname for the app | `sedaro` | Yes (for domain support) |

**Result**: Application will be accessible at `https://sedaro.example.com`

### SSL Certificate Management

The pipeline supports two certificate management approaches:

#### 1. AWS Certificate Manager (ACM) - Recommended
- **Automatic Discovery**: Pipeline searches for existing certificates
- **Supported Patterns**:
  - Exact match: `sedaro.example.com`
  - Wildcard: `*.example.com`
  - Subject Alternative Names (SAN) certificates
- **Manual Creation**: Create certificate in AWS Console if not found

#### 2. cert-manager with Let's Encrypt - Alternative
- Set `tls.certificate.useCertManager=true` in Helm values
- Requires cert-manager installation in cluster
- Automatic certificate provisioning

## Deployment Modes

### 1. Default Mode (No Domain Variables)
```bash
# No DOMAIN/HOST variables set
# Deploys with AWS ALB default URLs
```
- Uses ALB-generated hostnames
- HTTP-only configuration
- No custom domain setup

### 2. Domain Mode (Variables Set)
```bash
# DOMAIN=example.com
# HOST=sedaro
# Result: https://sedaro.example.com
```
- Custom domain configuration enabled
- HTTPS/TLS automatically configured
- Certificate auto-discovery and setup

## Helm Chart Configuration

### Domain Configuration
```yaml
domain:
  enabled: false           # Set via pipeline
  name: ""                # Set via DOMAIN variable
  host: ""                # Set via HOST variable
  fullName: ""            # Computed: host.domain
```

### TLS Configuration
```yaml
tls:
  enabled: false          # Auto-enabled with domain
  certificate:
    useACM: true         # Use AWS Certificate Manager
    arn: ""              # Auto-discovered or manual
    useCertManager: false # Alternative: cert-manager
    issuer: "letsencrypt-prod"
  redirect:
    enabled: true        # HTTP to HTTPS redirect
    statusCode: "HTTP_301"
```

## AWS ALB Annotations

When domain and TLS are enabled, the ingress automatically includes:

```yaml
annotations:
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:..."
  alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", ...}'
```

## Certificate Management

### Option 1: AWS Certificate Manager (Recommended)

1. **Request Certificate in ACM**:
   ```bash
   aws acm request-certificate \
     --domain-name "sedaro.example.com" \
     --validation-method DNS \
     --region us-east-1
   ```

2. **DNS Validation**:
   - Add CNAME record to Route53 for validation
   - Certificate becomes available after validation

3. **Wildcard Certificate** (covers all subdomains):
   ```bash
   aws acm request-certificate \
     --domain-name "*.example.com" \
     --validation-method DNS \
     --region us-east-1
   ```

### Option 2: cert-manager with Let's Encrypt

1. **Install cert-manager**:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

2. **Create ClusterIssuer**:
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-prod
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: your-email@example.com
       privateKeySecretRef:
         name: letsencrypt-prod
       solvers:
       - http01:
           ingress:
             class: alb
   ```

3. **Update Helm values**:
   ```yaml
   tls:
     certificate:
       useCertManager: true
       useACM: false
   ```

## Pipeline Workflow

The enhanced deployment pipeline:

1. **Reads Repository Variables**: `DOMAIN` and `HOST`
2. **Computes Full Domain**: `${HOST}.${DOMAIN}`
3. **Searches for Certificates**: ACM certificate discovery
4. **Configures Helm Values**: Domain and TLS settings
5. **Deploys Application**: With custom domain and HTTPS

### Pipeline Logs Example

```bash
Configuring custom domain: sedaro.example.com
Found ACM certificate: arn:aws:acm:us-east-1:123456789012:certificate/abcd-1234
Executing: helm upgrade --install sedaro-nano ... --set domain.enabled=true --set tls.enabled=true
```

## Route53 Configuration

Ensure your Route53 hosted zone is configured to point to the ALB:

1. **Get ALB DNS Name**:
   ```bash
   kubectl get ingress sedaro-nano -n sedaro-nano -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

2. **Create Route53 Record**:
   ```bash
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z123456789 \
     --change-batch '{
       "Changes": [{
         "Action": "CREATE",
         "ResourceRecordSet": {
           "Name": "sedaro.example.com",
           "Type": "CNAME",
           "TTL": 300,
           "ResourceRecords": [{"Value": "ALB-DNS-NAME"}]
         }
       }]
     }'
   ```

## Troubleshooting

### Common Issues

1. **Certificate Not Found**:
   ```
   No ACM certificate found for sedaro.example.com
   Consider creating one manually or using cert-manager
   ```
   **Solution**: Create ACM certificate or use cert-manager

2. **Route53 DNS Issues**:
   ```
   Domain not resolving to ALB
   ```
   **Solution**: Verify Route53 records point to ALB DNS name

3. **TLS Certificate Mismatch**:
   ```
   SSL certificate doesn't match domain
   ```
   **Solution**: Ensure certificate covers the exact domain or use wildcard

### Validation Commands

```bash
# Check domain resolution
nslookup sedaro.example.com

# Test HTTPS connectivity
curl -I https://sedaro.example.com

# Check certificate details
openssl s_client -connect sedaro.example.com:443 -servername sedaro.example.com

# Verify Kubernetes resources
kubectl get ingress -n sedaro-nano
kubectl describe ingress sedaro-nano -n sedaro-nano
```

## Security Considerations

- **Certificate Management**: Use ACM for automatic renewal
- **HTTPS Enforcement**: Automatic HTTP to HTTPS redirect
- **DNS Security**: Ensure Route53 hosted zone is properly secured
- **Access Control**: Configure proper security groups for ALB

## Cost Optimization

- **ACM Certificates**: Free for AWS resources
- **Route53**: Minimal cost for DNS queries
- **ALB**: Standard ALB pricing applies
- **Wildcard Certificates**: Cover multiple subdomains with single certificate

---

This enhancement provides enterprise-grade domain management while maintaining the existing functionality for deployments without custom domains.
