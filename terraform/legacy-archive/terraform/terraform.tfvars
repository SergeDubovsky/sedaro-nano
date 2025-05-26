# Demo environment configuration
project_name = "sedaro-nano"
environment  = "demo"
aws_region   = "us-east-1"

# Network configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# EKS Node configuration (cost-optimized for demo)
node_instance_types = ["t3.small"]
node_desired_size   = 1
node_max_size       = 2
node_min_size       = 1
