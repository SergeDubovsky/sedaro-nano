# Sedaro Nano Terraform Deployment Guide

## Overview

This guide covers deploying the Sedaro Nano infrastructure using the modular Terraform structure **exclusively via GitHub Actions**. All terraform operations run in the cloud - no local terraform execution required.

## Prerequisites

1. **GitHub Repository**: Write access to configure secrets
2. **AWS Account**: Access to AWS account `047142614703`
3. **Existing Bootstrap Resources**: Already deployed:
   - IAM Role: `arn:aws:iam::047142614703:role/sedaro-nano-github-actions-role`
   - S3 Bucket: `sedaro-nano-terraform-state`
   - DynamoDB Table: `sedaro-nano-terraform-state-lock`

## Quick Start - GitHub Actions Only

### 1. Configure GitHub Secrets

Set these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

**Required:**
- `AWS_ROLE_ARN`: `arn:aws:iam::047142614703:role/sedaro-nano-github-actions-role`

**Optional:**
- `ADMIN_USER_ARN`: Your IAM user/role ARN for kubectl access (leave empty if not needed)

### 2. Deploy Infrastructure via GitHub Actions

**Option A: Automatic Deployment**
```bash
git add .
git commit -m "Deploy modular terraform infrastructure"
git push origin main
```

**Option B: Manual Deployment**
1. Go to GitHub Actions tab in your repository
2. Select "Terraform Deploy Infrastructure" workflow
3. Click "Run workflow"
4. Click "Run workflow" again to confirm
- Kubernetes workloads will be deployed

## Cleanup (if needed)

### Via GitHub Actions
1. Go to GitHub Actions
2. Run "Terraform Destroy Infrastructure" workflow
3. Enter "destroy" when prompted

### Manual Cleanup
```bash
cd terraform/environments/demo
terraform destroy
```

## Monitoring and Troubleshooting

### Check EKS Cluster
```bash
kubectl cluster-info
kubectl get nodes
```

### Check Application Logs
```bash
kubectl logs -l app=sedaro-nano,tier=backend
kubectl logs -l app=sedaro-nano,tier=frontend
```

### Access Application
```bash
kubectl get service aws-load-balancer-webhook-service
# Get the LoadBalancer URL from the output
```
