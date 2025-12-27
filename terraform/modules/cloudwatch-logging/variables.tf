variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS IRSA"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch and S3"
  type        = number
  default     = 30
}
