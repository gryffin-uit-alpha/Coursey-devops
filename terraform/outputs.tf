output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.cluster.cluster_endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.cluster.cluster_name
}

output "configure_kubectl" {
  description = "Configure kubectl: Run this command to connect to your cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.cluster.cluster_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_controller_role_arn" {
  description = "ARN of the IAM role for ALB controller"
  value       = module.k8s_addons.alb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ARN of the IAM role for External DNS"
  value       = module.k8s_addons.external_dns_role_arn
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "Map of ECR repository names to URLs"
  value       = module.ecr.repository_urls
}

output "ecr_login_command" {
  description = "Command to authenticate Docker with ECR"
  value       = module.ecr.ecr_login_command
}

# CloudWatch Logging Outputs
output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for application logs"
  value       = module.cloudwatch_logging.cloudwatch_log_group_application
}

output "logs_s3_bucket" {
  description = "S3 bucket for archived logs"
  value       = module.cloudwatch_logging.s3_bucket_name
}
