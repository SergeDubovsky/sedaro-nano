# Sedaro Nano Deployment Validation Guide

## Overview
This guide provides comprehensive validation steps for deploying Sedaro Nano with custom domain configuration to AWS EKS.

## Prerequisites Validation

### 1. Infrastructure Components
- [ ] AWS EKS cluster is running
- [ ] AWS Load Balancer Controller is installed
- [ ] ECR repositories exist for both frontend and backend
- [ ] GitHub repository secrets are configured
- [ ] Route53 hosted zone exists for domain

### 2. Domain Configuration
- [ ] Domain: `k8sdemo.click` is available
- [ ] Subdomain: `sedaro.k8sdemo.click` is planned
- [ ] ACM certificate exists or can be created
- [ ] DNS records can be modified

### 3. GitHub Repository Variables
Required repository variables in GitHub:
- [ ] `DOMAIN` = `k8sdemo.click`
- [ ] `HOST` = `sedaro`

## Pre-Deployment Validation

### 1. Helm Chart Validation
```powershell
# Navigate to project directory
cd c:\Project\sedaro-nano

# Run basic template test
helm template test-release .\helm\sedaro-nano

# Run domain configuration test
helm template test-release .\helm\sedaro-nano \
  --set domain.enabled=true \
  --set domain.name="k8sdemo.click" \
  --set domain.host="sedaro" \
  --set domain.fullName="sedaro.k8sdemo.click" \
  --set tls.enabled=true \
  --set tls.certificate.arn="arn:aws:acm:us-east-1:123456789012:certificate/test-cert-id"

# Run helm lint
helm lint .\helm\sedaro-nano
```

### 2. AWS Configuration Validation
```powershell
# Check AWS CLI configuration
aws sts get-caller-identity

# Check EKS cluster access
kubectl cluster-info

# List available ACM certificates
aws acm list-certificates --region us-east-1

# Check Route53 hosted zones
aws route53 list-hosted-zones
```

### 3. ECR Repository Validation
```powershell
# Check ECR repositories
aws ecr describe-repositories

# Verify images exist (replace with actual account ID)
aws ecr describe-images --repository-name sedaro-nano/frontend
aws ecr describe-images --repository-name sedaro-nano/backend
```

## Deployment Steps

### 1. Manual Deployment Test
```powershell
# Set environment variables for testing
$env:DOMAIN = "k8sdemo.click"
$env:HOST = "sedaro"

# Deploy without domain first
helm upgrade --install sedaro-nano .\helm\sedaro-nano \
  --set image.frontendRepository="YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/sedaro-nano/frontend" \
  --set image.backendRepository="YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/sedaro-nano/backend" \
  --set image.tag="latest"

# Deploy with domain configuration
helm upgrade --install sedaro-nano .\helm\sedaro-nano \
  --set image.frontendRepository="YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/sedaro-nano/frontend" \
  --set image.backendRepository="YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/sedaro-nano/backend" \
  --set image.tag="latest" \
  --set domain.enabled=true \
  --set domain.name="k8sdemo.click" \
  --set domain.host="sedaro" \
  --set domain.fullName="sedaro.k8sdemo.click" \
  --set tls.enabled=true \
  --set tls.certificate.arn="YOUR_ACM_CERTIFICATE_ARN"
```

### 2. GitHub Actions Deployment
Trigger deployment through GitHub Actions by pushing to main branch with:
- Repository variables `DOMAIN` and `HOST` set
- Valid ACM certificate available

## Post-Deployment Validation

### 1. Kubernetes Resources
```powershell
# Check deployment status
kubectl get deployments -n default

# Check services
kubectl get services -n default

# Check ingress
kubectl get ingress -n default

# Check ingress details
kubectl describe ingress sedaro-nano

# Check pods status
kubectl get pods -n default

# Check pod logs
kubectl logs -l app.kubernetes.io/component=frontend
kubectl logs -l app.kubernetes.io/component=backend
```

### 2. Load Balancer Validation
```powershell
# Get ALB DNS name
kubectl get ingress sedaro-nano -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Check ALB listeners and targets in AWS Console
# Navigate to EC2 > Load Balancers > Target Groups
```

### 3. Domain and TLS Validation
```powershell
# Test HTTP redirect (should redirect to HTTPS)
curl -I http://sedaro.k8sdemo.click

# Test HTTPS access
curl -I https://sedaro.k8sdemo.click

# Test backend API
curl https://sedaro.k8sdemo.click/api/health

# Test SSL certificate
openssl s_client -connect sedaro.k8sdemo.click:443 -servername sedaro.k8sdemo.click
```

### 4. DNS Validation
```powershell
# Check DNS resolution
nslookup sedaro.k8sdemo.click

# Check CNAME record (should point to ALB)
nslookup sedaro.k8sdemo.click 8.8.8.8
```

## Troubleshooting

### Common Issues

#### 1. Certificate Issues
- **Problem**: TLS certificate not working
- **Solution**: 
  - Verify ACM certificate is issued and valid
  - Check certificate ARN in deployment
  - Ensure certificate covers the domain

#### 2. DNS Issues
- **Problem**: Domain not resolving
- **Solution**:
  - Check Route53 hosted zone
  - Verify DNS records point to ALB
  - Wait for DNS propagation (up to 48 hours)

#### 3. Load Balancer Issues
- **Problem**: ALB not provisioning
- **Solution**:
  - Check AWS Load Balancer Controller logs
  - Verify IAM permissions
  - Check ingress annotations

#### 4. Pod Issues
- **Problem**: Pods not starting
- **Solution**:
  - Check pod logs: `kubectl logs <pod-name>`
  - Verify ECR access and image pull
  - Check resource limits

### Validation Commands
```powershell
# Run comprehensive test
.\scripts\test-domain-config.ps1 -TestMode template -Domain "k8sdemo.click" -Subdomain "sedaro"

# Check ingress controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Check certificate manager (if using cert-manager)
kubectl get certificates -n default

# Monitor ingress events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Security Considerations

### 1. TLS Configuration
- [ ] Force HTTPS redirect is enabled
- [ ] Certificate is from trusted CA (ACM or Let's Encrypt)
- [ ] No mixed content warnings

### 2. Access Control
- [ ] Ingress is properly configured
- [ ] Backend API endpoints are secure
- [ ] No sensitive data exposed in logs

### 3. Network Security
- [ ] Security groups allow HTTPS traffic
- [ ] ALB is internet-facing as intended
- [ ] Backend services are not directly exposed

## Performance Validation

### 1. Load Testing
```powershell
# Simple performance test
for ($i = 1; $i -le 10; $i++) {
    Measure-Command { curl -s https://sedaro.k8sdemo.click | Out-Null }
}
```

### 2. Resource Monitoring
```powershell
# Check resource usage
kubectl top pods
kubectl top nodes

# Check HPA if configured
kubectl get hpa
```

## Success Criteria

### Deployment is successful when:
- [ ] All pods are running and ready
- [ ] Ingress has a valid ALB hostname
- [ ] Domain resolves to the ALB
- [ ] HTTPS is working with valid certificate
- [ ] HTTP redirects to HTTPS
- [ ] Frontend loads correctly
- [ ] Backend API responds to health checks
- [ ] No error logs in pods
- [ ] All validation tests pass

## Next Steps

1. **Monitor**: Set up monitoring and alerting
2. **Scale**: Configure HPA for auto-scaling
3. **Security**: Implement additional security measures
4. **Backup**: Set up backup and disaster recovery
5. **CI/CD**: Optimize deployment pipeline

---

**Note**: Replace placeholder values (YOUR_ACCOUNT, YOUR_ACM_CERTIFICATE_ARN) with actual values during deployment.
