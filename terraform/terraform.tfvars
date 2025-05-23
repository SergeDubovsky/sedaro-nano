# Demo environment configuration
project_name = "sedaro-nano"
environment  = "demo"
aws_region   = "us-west-2"

# Network configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]

# EKS Node configuration (cost-optimized for demo)
node_instance_types = ["t3.small"]
node_desired_size   = 1
node_max_size       = 2
node_min_size       = 1
