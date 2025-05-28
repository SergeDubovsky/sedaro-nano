# Graviton-Only Deployment Configuration

## Overview

The Sedaro Nano application has been configured to run exclusively on AWS Graviton (ARM64) instances for maximum cost optimization. This configuration eliminates the AMD64 node group and uses only ARM64 Graviton processors.

## Architecture Changes

### Before (Dual Architecture)
- **Main Node Group**: AMD64 instances (t3.small, AL2023_x86_64_STANDARD)
- **Graviton Node Group**: ARM64 instances (m6g.medium/large, AL2023_ARM_64_STANDARD)

### After (Graviton-Only)
- **Single Main Node Group**: ARM64 Graviton instances only (m6g.medium/large, AL2023_ARM_64_STANDARD)

## Configuration Details

### Instance Types
- **Primary**: `m6g.medium` and `m6g.large` (Graviton3 processors)
- **Capacity Type**: SPOT instances for maximum cost savings
- **AMI Type**: AL2023_ARM_64_STANDARD (future-proof, AL2 deprecated Nov 2025)

### Scaling Configuration
- **Minimum Size**: 1 node (must have at least 1 since it's the only node group)
- **Desired Size**: 1 node (minimal for demo)
- **Maximum Size**: 3 nodes (allows scaling when needed)

### Cost Optimization Features
- **SPOT Instances**: Up to 90% cost savings vs On-Demand
- **Graviton Processors**: Up to 40% better price/performance vs comparable x86 instances
- **Single NAT Gateway**: Reduces network costs
- **Optimized Instance Sizes**: Right-sized for the workload

## Infrastructure Components

### EKS Cluster
- **Kubernetes Version**: 1.32
- **Authentication**: API_AND_CONFIG_MAP
- **Endpoint Access**: Public (configurable)
- **VPC**: Custom VPC with public/private subnets

### Node Group Features
- **ARM64 Optimizations**: Custom bootstrap scripts for enhanced performance
- **IMDSv2**: Required for enhanced security
- **Enhanced Monitoring**: CloudWatch detailed monitoring enabled
- **Auto Scaling**: Cluster autoscaler compatible
- **Rolling Updates**: 25% max unavailable during updates

### Network Optimizations
- **Kernel Parameters**: Optimized for Kubernetes networking
- **Container Runtime**: Optimized containerd configuration for ARM64
- **VPC CNI**: Enhanced IP allocation for pod networking

## Application Compatibility

### Requirements for ARM64
All application components have been verified for ARM64 compatibility:

1. **Python Backend** (`app/`)
   - Base Image: `python:3.11-slim` (multi-arch)
   - Dependencies: All Python packages support ARM64

2. **React Frontend** (`web/`)
   - Base Image: `node:18-alpine` (multi-arch)
   - Build Tools: Node.js and npm work natively on ARM64

3. **Rust Query Engine** (`queries/`)
   - Rust compiles natively to ARM64
   - No architecture-specific dependencies

### Docker Images
All Docker images are built with multi-architecture support:
```dockerfile
# Automatically selects ARM64 variant when running on Graviton
FROM python:3.11-slim
FROM node:18-alpine
```

## Deployment Benefits

### Cost Savings
- **Compute**: 40%+ savings from Graviton vs comparable x86 instances
- **SPOT Pricing**: Up to 90% savings vs On-Demand pricing
- **Combined**: Up to 94% total compute cost reduction

### Performance
- **Graviton3**: Latest ARM64 processors with enhanced performance
- **Memory Bandwidth**: Higher memory bandwidth per vCPU
- **Network Performance**: Enhanced networking capabilities

### Sustainability
- **Energy Efficiency**: Graviton processors use up to 60% less energy
- **Carbon Footprint**: Reduced environmental impact

## Monitoring and Operations

### Labels and Tags
All resources are tagged for easy identification:
- `sedaro.io/architecture: arm64`
- `sedaro.io/node-type: graviton`
- `sedaro.io/cost-optimized: true`

### Cluster Autoscaler
- Configured to work with single ARM64 node group
- Automatic scaling based on pod resource requests
- SPOT instance handling for cost optimization

### Monitoring
- **CloudWatch**: Detailed instance and cluster metrics
- **Container Insights**: Kubernetes-native monitoring
- **Cost and Usage Reports**: Track cost savings

## Deployment Commands

### Terraform Deployment
```powershell
# Navigate to demo environment
cd terraform/environments/demo

# Initialize and plan
terraform init
terraform plan

# Deploy Graviton-only cluster
terraform apply
```

### Verify Deployment
```powershell
# Check node architecture
kubectl get nodes -o wide

# View node labels
kubectl get nodes --show-labels | grep arm64

# Check running pods
kubectl get pods -A -o wide
```

## Rollback Considerations

If you need to revert to dual architecture:
1. The previous configuration is preserved in git history
2. Restore the `main` AMD64 node group configuration
3. Re-add the removed variables and references
4. Update minimum size for Graviton group back to 0

## Best Practices

### Application Development
- **Multi-arch Images**: Always build Docker images for both AMD64 and ARM64
- **Testing**: Test applications on ARM64 before production deployment
- **Dependencies**: Verify all dependencies support ARM64

### Operations
- **Monitoring**: Monitor cost savings and performance metrics
- **Capacity Planning**: ARM64 instances may have different performance characteristics
- **SPOT Interruptions**: Implement proper handling for SPOT instance interruptions

## Troubleshooting

### Common Issues
1. **Pod Scheduling Failures**: Ensure container images support ARM64
2. **SPOT Interruptions**: Configure pod disruption budgets and node affinity
3. **Performance**: Monitor and adjust instance types based on workload requirements

### Verification Commands
```powershell
# Check node architecture
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}'

# Verify ARM64 images are running
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'
```

## Future Enhancements

### Potential Improvements
- **Bottlerocket OS**: Consider Bottlerocket for enhanced security and performance
- **Graviton4**: Upgrade to newer Graviton processors when available
- **Fargate**: Consider ARM64 Fargate for serverless workloads
- **Multi-Region**: Expand to multiple regions with Graviton availability

This Graviton-only configuration provides significant cost savings while maintaining performance and reliability for the Sedaro Nano application.
