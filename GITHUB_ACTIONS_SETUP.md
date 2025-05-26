# GitHub Actions Configuration for Terraform Deployment

## Required GitHub Secrets

To deploy the Sedaro Nano infrastructure using GitHub Actions, you need to configure the following secrets in your GitHub repository:

### 1. AWS_ROLE_ARN (Required)
The ARN of the IAM role that GitHub Actions will assume for AWS operations.

**Value:** `arn:aws:iam::047142614703:role/sedaro-nano-github-actions-role`

**How to set:**
1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AWS_ROLE_ARN`
5. Value: `arn:aws:iam::047142614703:role/sedaro-nano-github-actions-role`

### 2. ADMIN_USER_ARN (Optional)
The ARN of an IAM user or role that should have admin access to the EKS cluster. This is useful for local kubectl access or emergency access.

**Example values:**
- For an IAM user: `arn:aws:iam::047142614703:user/your-username`
- For an IAM role: `arn:aws:iam::047142614703:role/your-admin-role`
- Leave empty if not needed: (empty value)

**How to set:**
1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `ADMIN_USER_ARN`
5. Value: Your IAM user/role ARN or leave empty

## How the Variables Are Used

### In terraform-deploy.yml:
- `TF_VAR_github_actions_role_arn` = `${{ secrets.AWS_ROLE_ARN }}`
- `TF_VAR_admin_user_arn` = `${{ secrets.ADMIN_USER_ARN || '' }}`

### In terraform-destroy.yml:
- Same environment variables for consistent access

## EKS Cluster Access

The terraform configuration will:

1. **GitHub Actions Role**: Automatically granted `AmazonEKSClusterAdminPolicy` for CI/CD operations
2. **Admin User** (if specified): Granted `AmazonEKSClusterAdminPolicy` for manual kubectl access

## Deployment Process

Once the secrets are configured:

1. **Automatic Deployment**: Push to `main` branch to trigger deployment
2. **Manual Deployment**: Use "Run workflow" button in GitHub Actions
3. **Monitoring**: Watch the workflow progress in the Actions tab

## Verification

After deployment, you can verify access:

```bash
# Configure kubectl (if ADMIN_USER_ARN is set to your user)
aws eks update-kubeconfig --name sedaro-nano-demo --region us-east-1

# Test cluster access
kubectl get nodes
kubectl get namespaces
```

## Troubleshooting

If deployment fails:
1. Check that `AWS_ROLE_ARN` is correctly set
2. Verify the IAM role exists and has proper permissions
3. Ensure the S3 backend bucket exists (`sedaro-nano-terraform-state-us-east-1`)
4. Check the GitHub Actions workflow logs for specific errors

## Notes

- The `ADMIN_USER_ARN` secret is optional - if not set, only the GitHub Actions role will have cluster access
- The GitHub Actions role ARN is used both for AWS authentication and EKS cluster access
- All terraform state is stored in the S3 backend with DynamoDB locking
