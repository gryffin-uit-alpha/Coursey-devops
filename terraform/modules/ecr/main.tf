# ECR Repositories for Coursey Application
# Creates container registries for each service

variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["coursey/php", "coursey/nginx", "coursey/mysql", "coursey/python"]
}

variable "image_retention_count" {
  description = "Number of images to retain per repository"
  type        = number
  default     = 5
}

resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repository_names)
  name     = each.value

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allow deletion even if images exist

  tags = {
    Project = "coursey"
  }
}

# Lifecycle policy to limit stored images (cost saving)
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last ${var.image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}

output "repository_urls" {
  description = "Map of repository names to their URLs"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
