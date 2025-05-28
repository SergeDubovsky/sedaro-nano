# Migration Guide: Dual Architecture to Graviton-Only

## Overview

This document describes the migration from a dual-architecture EKS cluster (AMD64 + ARM64) to a Graviton-only (ARM64) configuration for maximum cost optimization.

## Changes Made

### 1. EKS Cluster Configuration (`terraform/modules/eks-cluster/main.tf`)

**Before:**
- Two node groups: `main` (AMD64) and `graviton` (ARM64)
- Default instance types: `t3.small` (AMD64) and `m6g.medium` (ARM64)

**After:**
- Single node group: `main` (ARM64 Graviton only)
- Instance types: `m6g.medium` and `m6g.large` (Graviton3)
- Node group renamed from `graviton` to `main` for clarity

### 2. Variable Cleanup

**Removed Variables:**
- `node_instance_types` - AMD64 instance types
- `node_desired_size` - AMD64 scaling configuration
- `node_max_size` - AMD64 scaling configuration  
- `node_min_size` - AMD64 scaling configuration
- `node_ami_type` - AMD64 AMI configuration
- `node_capacity_type` - AMD64 capacity configuration
- `node_volume_*` - AMD64 storage configuration
- `graviton_taint_arm_workloads` - No longer needed with single node group

**Updated Variables:**
- `graviton_min_size`: Changed from `0` to `1` (required for single node group)
- All Graviton variables now represent the primary (and only) node group

### 3. Environment Configuration Updates

**File:** `terraform/environments/demo/variables.tf`
- Removed all AMD64 node group variables
- Updated descriptions to reflect Graviton as primary node group
- Set minimum Graviton nodes to 1 for cluster availability

**File:** `terraform/environments/demo/main.tf`
- Removed AMD64 node group variable references
- Cleaned up module configuration
- Removed taint configuration reference

## Benefits of Graviton-Only Configuration

### Cost Optimization
- **40%+ better price/performance** vs comparable x86 instances
- **SPOT instances** for up to 90% additional savings
- **Simplified architecture** reduces management overhead
- **Single node group** eliminates dual-architecture complexity

### Performance Benefits
- **Graviton3 processors** with enhanced performance per dollar
- **Higher memory bandwidth** per vCPU
- **Better energy efficiency** (up to 60% less energy consumption)
- **Native ARM64 performance** for compatible workloads

### Operational Simplicity
- **Single architecture** to manage and monitor
- **Unified deployment strategy** for all workloads
- **Simplified troubleshooting** with single instance type family
- **Consistent performance characteristics** across all nodes

## Deployment Impact

### Application Compatibility
✅ **All application components verified for ARM64 compatibility:**
- Python backend: Native ARM64 support
- React frontend: Node.js works natively on ARM64
- Rust query engine: Compiles natively to ARM64
- All Docker images: Multi-architecture builds supported

### Infrastructure Changes
- **No downtime required** for new deployments
- **Existing clusters** can be migrated with standard rolling update
- **Container images** automatically use ARM64 variants
- **Kubernetes workloads** schedule normally without modification

## Migration Steps for Existing Clusters

If migrating an existing dual-architecture cluster:

### 1. Pre-Migration Verification
```powershell
# Verify all container images support ARM64
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Check current node architecture distribution
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.architecture}{"\n"}{end}'
```

### 2. Apply Configuration Changes
```powershell
# Update Terraform configuration
cd terraform/environments/demo
terraform plan  # Review changes
terraform apply # Apply Graviton-only configuration
```

### 3. Node Group Transition
```powershell
# Monitor node replacement
kubectl get nodes -w

# Verify all nodes are ARM64
kubectl get nodes -o wide
```

### 4. Validate Application Health
```powershell
# Check pod scheduling on new ARM64 nodes
kubectl get pods -o wide

# Verify application endpoints
kubectl get services
```

## Rollback Plan

If rollback is needed:

### 1. Restore Previous Configuration
```powershell
# Checkout previous git commit
git checkout <previous-commit>

# Apply previous configuration
terraform apply
```

### 2. Alternative: Re-add AMD64 Node Group
```hcl
# Add back to eks_managed_node_groups in main.tf
amd64 = {
  name            = "${local.name}-amd64"
  instance_types  = ["t3.small"]
  # ... previous configuration
}
```

## Monitoring and Validation

### Key Metrics to Monitor
- **Cost savings**: CloudWatch Cost Explorer
- **Performance**: Application response times
- **Availability**: Node and pod health
- **Resource utilization**: CPU and memory usage

### Validation Commands
```powershell
# Verify ARM64 architecture
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}'

# Check resource usage
kubectl top nodes
kubectl top pods

# Monitor cluster autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler
```

## Expected Outcomes

### Cost Savings
- **Immediate**: 40%+ reduction in compute costs vs comparable x86
- **With SPOT**: Up to 94% total compute cost reduction
- **Long-term**: Simplified architecture reduces operational overhead

### Performance
- **Consistent**: Graviton3 provides predictable performance
- **Efficient**: Better performance per dollar spent
- **Scalable**: Auto-scaling works seamlessly with single node group

### Operations
- **Simplified**: Single architecture to manage
- **Reliable**: Proven Graviton technology in production
- **Future-proof**: AWS continues investing in ARM64 ecosystem

This migration represents a significant step forward in cost optimization while maintaining full functionality and performance of the Sedaro Nano application.
