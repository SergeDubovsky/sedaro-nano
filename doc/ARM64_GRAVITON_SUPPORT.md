# ARM64 Graviton Support for Sedaro Nano

## Overview

This document describes the ARM64 (Graviton) support added to the Sedaro Nano platform, enabling deployment on AWS Graviton instances for improved cost efficiency and performance.

## 🚀 What's Included

### **Multi-Architecture Docker Images**
- **Automatic builds** for both `linux/amd64` and `linux/arm64` platforms
- **Cross-platform compatibility** ensuring containers run on both x86 and ARM64 nodes
- **CI/CD optimization** with platform-specific caching and build strategies

### **Dual Node Group EKS Cluster**
- **AMD64 Node Group**: Traditional x86 instances (t3.small by default)
- **ARM64 Node Group**: Graviton instances (m6g.medium by default) with SPOT pricing
- **Intelligent scheduling** with preference for ARM64 nodes for cost optimization
- **Fallback capability** to AMD64 nodes when ARM64 capacity is unavailable

### **Smart Kubernetes Scheduling**
- **Node affinity** preferring ARM64 Graviton nodes for cost savings
- **Automatic fallback** to AMD64 nodes if ARM64 nodes are unavailable
- **Flexible deployment** allowing mixed-architecture workloads

## 💰 Cost Benefits

### **Graviton Instance Advantages**
- **Up to 40% better price-performance** compared to x86 instances
- **20% lower costs** for CPU-intensive workloads
- **Energy efficient** with better performance per watt
- **SPOT pricing** support for additional 60-90% cost savings

### **Cost Optimization Strategy**
```yaml
# Default configuration prioritizes cost savings
graviton_capacity_type: "SPOT"        # Use SPOT instances
graviton_min_size: 0                  # Scale to zero when not needed
multiArch.preferArm64: true           # Prefer cheaper ARM64 nodes
```

## 🏗️ Architecture Components

### **1. Multi-Architecture Docker Build**
```yaml
# CI/CD builds both architectures
platforms: linux/amd64,linux/arm64
```

**Backend (Python + Rust):**
- ✅ `rust:1.84-slim` - ARM64 compatible
- ✅ `python:3.12-slim` - ARM64 compatible  
- ✅ Rust cross-compilation works seamlessly

**Frontend (Node.js + Nginx):**
- ✅ `node:20-bookworm` - ARM64 compatible
- ✅ `nginx:stable-alpine` - ARM64 compatible
- ✅ Native ARM64 performance

### **2. EKS Node Groups**

**AMD64 Node Group (main):**
```hcl
instance_types = ["t3.small"]
ami_type = "AL2023_x86_64_STANDARD"
capacity_type = "SPOT"
```

**ARM64 Node Group (graviton):**
```hcl
instance_types = ["m6g.medium", "m6g.large"] 
ami_type = "AL2023_ARM_64_STANDARD"
capacity_type = "SPOT"
min_size = 0  # Can scale to zero
```

### **3. Intelligent Pod Scheduling**
```yaml
# Pods prefer ARM64 but can fallback to AMD64
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
      - key: kubernetes.io/arch
        operator: In
        values: [arm64]
  - weight: 50
    preference:
      matchExpressions:
      - key: kubernetes.io/arch
        operator: In
        values: [amd64]
```

## 🚀 Deployment Instructions

### **Quick Start (ARM64 Enabled)**
```bash
# Deploy with Graviton support
cd terraform/environments/demo
terraform apply

# Verify multi-arch node groups
kubectl get nodes -o wide
```

### **Configuration Options**

**Enable ARM64-only workloads:**
```hcl
# terraform.tfvars
graviton_taint_arm_workloads = true
```

**Customize instance types:**
```hcl
# terraform.tfvars
graviton_instance_types = ["m6g.large", "m6g.xlarge"]
graviton_desired_size = 2
```

**Helm deployment with ARM64 preference:**
```bash
helm upgrade --install sedaro-nano ./helm/sedaro-nano \
  --set multiArch.enabled=true \
  --set multiArch.nodeAffinity.preferArm64=true
```

## 🔧 Configuration Reference

### **Terraform Variables**
```hcl
# ARM64 Graviton configuration
graviton_instance_types        = ["m6g.medium"]
graviton_capacity_type         = "SPOT"
graviton_ami_type             = "AL2023_ARM_64_STANDARD"
graviton_min_size             = 0
graviton_max_size             = 3
graviton_desired_size         = 1
graviton_taint_arm_workloads  = false
```

### **Helm Values**
```yaml
# Multi-architecture support
multiArch:
  enabled: true
  nodeAffinity:
    preferArm64: true
    allowFallback: true
```

## 📊 Monitoring & Verification

### **Check Node Architecture**
```bash
# View node labels
kubectl get nodes --show-labels | grep arch

# Check pod placement
kubectl get pods -o wide
```

### **Verify Container Architecture**
```bash
# Check running container architecture
kubectl exec -it <pod-name> -- uname -m
# ARM64: aarch64
# AMD64: x86_64
```

### **Monitor Cost Savings**
```bash
# View SPOT instance usage
kubectl get nodes -l node.kubernetes.io/capacity-type=spot

# Check Graviton node utilization
kubectl top nodes -l kubernetes.io/arch=arm64
```

## 🛠️ Troubleshooting

### **Common Issues**

**ARM64 Node Not Available:**
- Verify AWS region supports Graviton instances
- Check SPOT instance availability
- Increase `graviton_max_size` if needed

**Pod Stuck Pending:**
- Check node affinity configuration
- Verify multi-arch images are built
- Ensure sufficient resources on ARM64 nodes

**Performance Issues:**
- Monitor CPU/memory usage on different architectures
- Adjust resource requests/limits appropriately
- Consider instance type optimization

### **Debug Commands**
```bash
# Check node capacity
kubectl describe nodes

# View pod scheduling events
kubectl describe pod <pod-name>

# Check node group status
aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <nodegroup>
```

## 📈 Performance Considerations

### **Graviton3 Benefits**
- **25% better compute performance** than Graviton2
- **2x better floating-point performance** 
- **50% better memory bandwidth**
- **Enhanced cryptographic performance**

### **Workload Compatibility**
- ✅ **Python applications** - Native ARM64 support
- ✅ **Rust applications** - Excellent ARM64 performance
- ✅ **Node.js applications** - Native ARM64 support
- ✅ **Nginx** - Optimized for ARM64

## 🔄 Migration Strategy

### **Phase 1: Hybrid Deployment**
1. Deploy with both node groups
2. Allow workloads to prefer ARM64
3. Monitor performance and costs

### **Phase 2: ARM64 Optimization**
1. Analyze workload placement
2. Optimize resource allocations
3. Consider ARM64-specific optimizations

### **Phase 3: Cost Optimization**
1. Increase ARM64 node capacity
2. Reduce AMD64 node group size
3. Enable auto-scaling based on demand

This ARM64 Graviton support provides significant cost savings while maintaining performance and reliability, making it an excellent choice for production workloads.
