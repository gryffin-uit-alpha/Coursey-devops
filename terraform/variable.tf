variable "cluster_name" {
  type    = string
  default = "gryffin-eks-cluster"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "gryffin-uit.site"
}

variable "hosted_zone_id" {
  type    = string
  default = "Z0553992X17INP7N2VQV"
}

variable "grafana_password" {
  type      = string
  sensitive = true
}
