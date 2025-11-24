output "alb_controller_role_arn" {
  description = "ARN of the IAM role for ALB controller"
  value       = module.lb_role.iam_role_arn
}

output "external_dns_role_arn" {
  description = "ARN of the IAM role for External DNS"
  value       = module.external_dns_role.iam_role_arn
}

output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring stack"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}
