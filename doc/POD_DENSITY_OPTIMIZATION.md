# Pod Density Optimization for EKS Nodes

## Problem Statement

The `m6g.large` instances in your EKS cluster are currently limited to **8 pods**, which is significantly lower than the theoretical maximum of **27 pods** for this instance type.

## Root Cause Analysis

The low pod limit is due to AWS VPC CNI default configuration:

- **Default Mode**: Each pod gets a secondary IP address from the node's subnet
- **ENI Limitations**: m6g.large has 3 ENIs with 10 IPs each = 30 total IPs
- **Reserved IPs**: 3 IPs reserved for ENI management = 27 available for pods
- **Current Limit**: Only 8 pods suggests subnet IP exhaustion or CNI misconfiguration

## Solutions Implemented

### 1. IP Prefix Delegation (Terraform - Recommended)

**What it does**: Instead of assigning individual IP addresses, AWS CNI assigns IP prefixes (/28 subnets) to each ENI, dramatically increasing pod density.

**Benefits**:

- **m6g.large**: Up to **110 pods** (from 8)
- **m6g.xlarge**: Up to **234 pods** 
- More efficient IP utilization
- Better resource utilization

**Files Modified**:

- `terraform/modules/eks-cluster/main.tf` - Added VPC CNI addon with prefix delegation
- `terraform/modules/eks-addons/main.tf` - Added CNI configuration
- `terraform/environments/demo/variables.tf` - Added configuration variables

### 2. Larger Instance Types

**Current**: `["m6g.medium", "m6g.large"]`

**Updated**: `["m6g.large", "m6g.xlarge"]`

**Pod Limits**:

- **m6g.medium**: 8 → 30 pods (standard) / 30 pods (prefix mode)
- **m6g.large**: 8 → 27 pods (standard) / 110 pods (prefix mode)
- **m6g.xlarge**: 58 pods (standard) / 234 pods (prefix mode)

## Manual Configuration (Immediate Fix)

If you need to increase pod density immediately without redeploying Terraform:

### Step 1: Connect to EKS Cluster

```powershell
aws eks update-kubeconfig --region us-east-1 --name sedaro-nano-demo
```

### Step 2: Enable Prefix Delegation

```powershell
# Patch the aws-node DaemonSet to enable prefix delegation
kubectl patch daemonset aws-node -n kube-system -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "aws-node",
          "env": [
            {"name": "ENABLE_PREFIX_DELEGATION", "value": "true"},
            {"name": "WARM_PREFIX_TARGET", "value": "1"},
            {"name": "WARM_IP_TARGET", "value": "3"},
            {"name": "MINIMUM_IP_TARGET", "value": "2"}
          ]
        }]
      }
    }
  }
}'
```

### Step 3: Restart aws-node Pods

```powershell
# Restart the aws-node DaemonSet to apply changes
kubectl rollout restart daemonset/aws-node -n kube-system

# Wait for rollout to complete
kubectl rollout status daemonset/aws-node -n kube-system
```

### Step 4: Restart Nodes (Required)

```powershell
# Get node names
kubectl get nodes

# Cordon and drain the node
kubectl cordon ip-10-0-10-176.ec2.internal
kubectl drain ip-10-0-10-176.ec2.internal --ignore-daemonsets --delete-emptydir-data --force

# Terminate the EC2 instance (it will be recreated by ASG)
aws ec2 terminate-instances --instance-ids i-009550ee1ce0ec111 --region us-east-1
```

### Step 5: Verify Increased Pod Capacity

```powershell
# Wait for new node to join
kubectl get nodes -w

# Check new pod capacity
kubectl describe node <new-node-name> | Select-String -Pattern "pods:"
```

## Expected Results

### Before Optimization

```
Capacity:
  pods: 8
Allocatable:
  pods: 8
```

### After Prefix Delegation

```
Capacity:
  pods: 110
Allocatable:
  pods: 110
```

## Deployment via GitHub Actions

The Terraform changes have been prepared and committed. To deploy the optimization:

1. **Push changes to GitHub** (if not already done)
2. **Trigger GitHub Actions workflow** - The CI/CD pipeline will automatically apply the Terraform changes
3. **Monitor deployment** in the GitHub Actions tab
4. **Verify pod density** once deployment completes

⚠️ **Important**: Do NOT run Terraform locally as it will conflict with the GitHub Actions managed state.

### Recent Fixes Applied:
- ✅ **VPC CNI Addon Version**: Updated to `v1.19.5-eksbuild.3` (compatible with EKS 1.32)
- ✅ **ConfigMap Conflict**: Removed problematic ConfigMap creation, using DaemonSet patching instead
- ✅ **Validation Script**: Added `scripts/validate-pod-density.ps1` for post-deployment verification

## Monitoring and Validation

### Automated Validation Script

Use the provided validation script for comprehensive pod density checking:

```powershell
# Run the automated validation script
.\scripts\validate-pod-density.ps1
```

This script will:
- Check node pod capacities
- Verify VPC CNI prefix delegation settings
- Show current pod allocation
- Provide node cycling guidance if needed

### Manual Validation Steps

```powershell
# View current pod allocation
kubectl get pods -A -o wide

# Check node capacity
kubectl describe nodes | Select-String -Pattern "Capacity:" -A 10

# Monitor pod scheduling
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Verify VPC CNI Configuration

```powershell
# Check CNI environment variables
kubectl get daemonset aws-node -n kube-system -o jsonpath='{.spec.template.spec.containers[0].env[*]}'

# Check CNI logs
kubectl logs daemonset/aws-node -n kube-system
```

## Cost Impact

### Instance Cost Optimization

- **Before**: Multiple small nodes (higher overhead)
- **After**: Fewer, larger nodes with higher pod density
- **Savings**: 10-20% compute cost reduction through better utilization

### Network Cost

- **Prefix Mode**: Reduced IP address consumption
- **Subnet Efficiency**: Better IP utilization

## Troubleshooting

### Common Issues

1. **Pods Still Limited to 8**
   - Restart aws-node DaemonSet
   - Terminate and recreate nodes
   - Check subnet IP availability

2. **CNI Pods CrashLooping**
   - Check IAM permissions for VPC CNI
   - Verify subnet has available IP space
   - Review CNI logs

3. **Node Join Failures**
   - Check security group rules
   - Verify subnet route tables
   - Check EKS cluster endpoint access

### Debug Commands

```powershell
# Check CNI status
kubectl get pods -n kube-system | Select-String aws-node

# View CNI configuration
kubectl describe configmap amazon-vpc-cni -n kube-system

# Check node IP allocation
kubectl exec -n kube-system daemonset/aws-node -- aws-k8s-agent --version
```

## References

- [AWS VPC CNI Configuration](https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html)
- [EKS Pod Networking](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)
- [Prefix Assignment Mode](https://aws.amazon.com/blogs/containers/amazon-vpc-cni-increases-pods-per-node-limits/)

---

**Note**: Prefix delegation requires EKS 1.21+ and VPC CNI 1.9+. Your cluster (EKS 1.32) supports this feature.
