Hi Sedaro team!

Here is what I did with the Sedaro Nano challenge:

**Main achievements:**
- Transformed the basic Sedaro Nano mockup into a near production-ready application
- Implemented a complete CI/CD pipeline using GitHub Actions with automated ECR integration
- Deployed the application on AWS EKS with native AWS ALB ingress controller
- Added comprehensive monitoring and logging using AWS CloudWatch
- Added multi-layered security features like IMDSv2 enforcement, EBS encryption, ECR vulnerability scanning, and private subnets

The deployment is fully automated using Terraform, which allows for easy scaling and management of the infrastructure. Currently the project is set up for a single environment (demo), but it can be easily extended to multiple environments like staging and production.

**Infrastructure modules:**
- bootstrap module - sets up the AWS foundation with S3 bucket permissions and OIDC role for the CI/CD pipeline running in GitHub Actions
- eks-cluster module - creates the EKS cluster with optimized node groups and security configurations
- github-secrets module - automates the deployment secrets, allowing fully automated deployment without manual intervention

**CI/CD workflows:**
- ci.yml - the application build pipeline, which builds the Docker images and pushes them to ECR along with helm charts
- deploy-k8s.yml - a standalone deployment pipeline for the Kubernetes cluster, which deploys the application using Helm. Normally it is invoked at the end of the ci.yml workflow if it was successful
- terraform-deploy.yml - the Terraform deployment pipeline, which deploys the infrastructure using Terraform
- terraform-destroy.yml - the Terraform destroy pipeline, which destroys the infrastructure using Terraform

**Key technical features implemented:**

- Multi-layered security: IMDSv2 enforcement (http_tokens="required"), ECR vulnerability scanning, EBS encryption at rest
- Cost optimization: SPOT instances, single NAT gateway, optimized resource allocation
- Near-production-ready EKS cluster with managed node groups, auto-scaling, and multi-AZ deployment
- Docker build optimization: Multi-stage builds for both frontend and backend containers with build caching in GitHub Actions. This reduces image sizes and speeds up CI/CD pipeline by reusing layers between builds, significantly improving deployment times

**Things I would like to improve if I had more time:**
- Mutual TLS setup for the ALB ingress controller, which would allow for secure communication between the ALB and the application pods. This would require additional configuration in the Helm chart and the Kubernetes cluster
- TLS setup for the ALB. I would use cert-manager and Let's Encrypt for automated certificate management
- Tracing integration with OpenTelemetry and AWS X-Ray to get better insights into the application performance and errors
- Caching layer with Redis or AWS ElastiCache to improve the performance of the application
- Progressive deployment strategies like canary deployments using Flagger for safer releases
