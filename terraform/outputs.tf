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

