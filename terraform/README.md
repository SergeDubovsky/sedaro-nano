# Sedaro Nano - Terraform Infrastructure

This directory contains the Terraform Infrastructure as Code (IaC) for deploying the Sedaro Nano application to AWS EKS.

## Architecture

- **VPC**: Custom VPC with public and private subnets across 2 AZs
- **EKS Cluster**: Managed Kubernetes cluster with SPOT instances for cost optimization
- **Node Groups**: Single managed node group with t3.small instances
- **AWS Load Balancer Controller**: For handling ingress traffic

## Cost Optimization Features

- **SPOT Instances**: Uses SPOT instances instead of On-Demand for significant cost savings
- **Single NAT Gateway**: Uses one NAT gateway instead of per-AZ for cost efficiency
- **Minimal Node Count**: Starts with 1 node, can scale to 2 maximum
- **Small Instance Types**: Uses t3.small instances suitable for demo workloads

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **kubectl** installed for cluster management

## Deployment Steps

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply the Infrastructure

```bash
terraform apply
```

This will create:
- VPC and networking components
- EKS cluster
- Node group with SPOT instances
- AWS Load Balancer Controller

### 4. Configure kubectl

After successful deployment, configure kubectl to connect to your cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name sedaro-nano-demo
```

### 5. Verify Cluster Access

```bash
kubectl get nodes
kubectl get pods -A
```

## Deploying the Application

After the infrastructure is ready, deploy your Sedaro Nano application:

```bash
# From the project root
kubectl apply -f k8s/
```

## Monitoring Costs

- Monitor your AWS costs in the AWS Cost Explorer
- SPOT instances can be interrupted, but provide significant cost savings
- Consider setting up AWS Budgets for cost alerts

## Cleanup

To destroy the infrastructure and avoid ongoing costs:

```bash
terraform destroy
```

**Important**: Always run `terraform destroy` when you're done with the demo to avoid unnecessary AWS charges.

## Configuration

Key configuration options in `terraform.tfvars`:

- `node_instance_types`: Instance types for worker nodes
- `node_desired_size`: Number of nodes to start with
- `aws_region`: AWS region for deployment

## Security Considerations

- Cluster endpoint is publicly accessible (suitable for demo)
- Worker nodes are in private subnets
- IAM roles follow principle of least privilege
- For production, consider enabling private endpoint access

## Troubleshooting

### Common Issues

1. **Insufficient IAM permissions**: Ensure your AWS credentials have EKS and VPC permissions
2. **Node group fails to start**: Check SPOT instance availability in your region
3. **Load balancer controller issues**: Verify IRSA role permissions

### Useful Commands

```bash
# Check cluster status
kubectl get nodes

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# View cluster info
kubectl cluster-info

# Check terraform state
terraform show
```
