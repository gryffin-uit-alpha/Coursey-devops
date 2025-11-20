output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Configure kubectl: Run this command to connect to your cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}

output "load_balancer_hostname" {
  description = "Load Balancer endpoint"
  value       = try(data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname, "Đang chờ tạo...")
}
