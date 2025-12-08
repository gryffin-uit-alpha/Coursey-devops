
# Module 1: Networking (VPC, Subnets)
module "networking" {
  source = "./modules/networking"

  cluster_name = var.cluster_name
}

# Module 2: EKS Cluster
module "cluster" {
  source = "./modules/cluster"

  cluster_name = var.cluster_name
  vpc_id       = module.networking.vpc_id
  subnet_ids   = module.networking.private_subnets
}

# Module 3: Kubernetes Addons
module "k8s_addons" {
  source = "./modules/k8s-addons"

  cluster_name      = var.cluster_name
  region            = var.region
  vpc_id            = module.networking.vpc_id
  oidc_provider_arn = module.cluster.oidc_provider_arn

  # DNS Configuration
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id

  # Monitoring Configuration
  grafana_password = var.grafana_password

  # Ensure cluster is ready before installing addons
  depends_on = [module.cluster]
}
