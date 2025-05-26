# Sedaro Nano Terraform Deployment Guide

## Overview

This guide covers deploying the Sedaro Nano infrastructure using the modular Terraform structure via GitHub Actions.

## Prerequisites

1. **AWS Account**: Access to AWS account `047142614703`
2. **GitHub Repository**: Write access to configure secrets
3. **Existing Bootstrap Resources**: The following resources already exist:
   - IAM Role: `arn:aws:iam::047142614703:role/sedaro-nano-github-actions-role`
   - S3 Bucket: `sedaro-nano-terraform-state-us-east-1`
   - DynamoDB Table: `sedaro-nano-terraform-locks`

## Quick Start

### 1. Configure GitHub Secrets

**Required:**
- `AWS_ROLE_ARN`: `arn:aws:iam::047142614703:role/sedaro-nano-github-actions-role`

**Optional:**
- `ADMIN_USER_ARN`: Your IAM user/role ARN for kubectl access (or leave empty)

See [GITHUB_ACTIONS_SETUP.md](../GITHUB_ACTIONS_SETUP.md) for detailed instructions.

### 2. Deploy Infrastructure

**Option A: Automatic Deployment**
```bash
git add .
git commit -m "Deploy modular terraform infrastructure"
git push origin main
```

**Option B: Manual Deployment**
1. Go to GitHub Actions tab
2. Select "Terraform Infrastructure (Two-Stage)"
3. Click "Run workflow"
- Kubernetes workloads will be deployed

## Cleanup (if needed)

### Via GitHub Actions
1. Go to GitHub Actions
2. Run "Destroy Infrastructure (Two-Stage)" workflow
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
