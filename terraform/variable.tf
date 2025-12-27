variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  # User must provide via terraform.tfvars
}

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "grafana_password" {
  description = "Password for Grafana Admin (set via TF_VAR_grafana_password)"
  type        = string
  sensitive   = true
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string
  # User must provide via terraform.tfvars
}

variable "domain_name" {
  description = "Domain name for the application (e.g., example.com)"
  type        = string
  # User must provide via terraform.tfvars
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch and S3"
  type        = number
  default     = 30
}
