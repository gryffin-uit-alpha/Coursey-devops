variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Tên của EKS Cluster"
  default     = "kube-gryffin-uit-site"
}

variable "domain_name" {
  description = "Domain chính của dự án"
  default     = "gryffin-uit.site"
}


variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID cho domain gryffin-uit.site"
  type        = string
  # default   = "Z0553992X17INP7N2VQV" 
}

variable "node_instance_type" {
  default = "t3.small"
}

variable "node_count" {
  default = 4
}
