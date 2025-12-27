# ==============================================================================
# Coursey DevOps Makefile
# ==============================================================================
# Common commands for managing the infrastructure and application
# Run 'make help' to see all available commands
# ==============================================================================

.PHONY: help init validate terraform-init terraform-plan terraform-apply terraform-destroy helm-deploy helm-uninstall clean

# Colors for output
CYAN := \033[36m
RESET := \033[0m

# Default target
help:
	@echo ""
	@echo "$(CYAN)Coursey DevOps Commands$(RESET)"
	@echo "========================"
	@echo ""
	@echo "$(CYAN)Setup:$(RESET)"
	@echo "  make init              - Initialize project (copy example config files)"
	@echo "  make validate          - Validate configuration files exist"
	@echo ""
	@echo "$(CYAN)Terraform:$(RESET)"
	@echo "  make terraform-init    - Initialize Terraform with backend config"
	@echo "  make terraform-plan    - Run Terraform plan"
	@echo "  make terraform-apply   - Apply Terraform changes"
	@echo "  make terraform-destroy - Destroy infrastructure (use with caution!)"
	@echo ""
	@echo "$(CYAN)Docker/ECR:$(RESET)"
	@echo "  make docker-build      - Build all Docker images locally"
	@echo "  make ecr-login         - Login to Amazon ECR"
	@echo "  make docker-push       - Tag and push images to ECR"
	@echo ""
	@echo "$(CYAN)Kubernetes/Helm:$(RESET)"
	@echo "  make kubeconfig        - Update kubeconfig for EKS cluster"
	@echo "  make helm-deploy       - Deploy application via Helm"
	@echo "  make helm-uninstall    - Uninstall Helm release"
	@echo "  make pods              - List all running pods"
	@echo "  make logs              - Tail logs for a pod"
	@echo ""
	@echo "$(CYAN)Cleanup:$(RESET)"
	@echo "  make clean             - Clean up local Terraform files"
	@echo ""


# Initialize project with example files
init:
	@echo "$(CYAN)Initializing project...$(RESET)"
	@cp -n example.env .env 2>/dev/null || echo "  ⏭️  .env already exists, skipping"
	@cp -n terraform/terraform.tfvars.example terraform/terraform.tfvars 2>/dev/null || echo "  ⏭️  terraform.tfvars already exists, skipping"
	@cp -n terraform/backend.hcl.example terraform/backend.hcl 2>/dev/null || echo "  ⏭️  backend.hcl already exists, skipping"
	@cp -n helm-charts/coursey-backend/values.example.yaml helm-charts/coursey-backend/values-local.yaml 2>/dev/null || echo "  ⏭️  values-local.yaml already exists, skipping"
	@echo ""
	@echo "$(CYAN)✅ Done! Please edit the following files with your configuration:$(RESET)"
	@echo "  - .env"
	@echo "  - terraform/terraform.tfvars"
	@echo "  - terraform/backend.hcl"
	@echo "  - helm-charts/coursey-backend/values-local.yaml"
	@echo ""

# Validate that required config files exist
validate:
	@echo "$(CYAN)Validating configuration...$(RESET)"
	@test -f terraform/terraform.tfvars || (echo "❌ Missing: terraform/terraform.tfvars" && exit 1)
	@test -f terraform/backend.hcl || (echo "❌ Missing: terraform/backend.hcl" && exit 1)
	@test -f helm-charts/coursey-backend/values-local.yaml || (echo "❌ Missing: helm-charts/coursey-backend/values-local.yaml" && exit 1)
	@echo "$(CYAN)✅ All required configuration files present$(RESET)"

# Terraform commands
terraform-init: validate
	@echo "$(CYAN)Initializing Terraform...$(RESET)"
	cd terraform && terraform init -backend-config=backend.hcl

terraform-plan: terraform-init
	@echo "$(CYAN)Running Terraform plan...$(RESET)"
	cd terraform && terraform plan -var-file=terraform.tfvars

terraform-apply: terraform-init
	@echo "$(CYAN)Applying Terraform changes...$(RESET)"
	cd terraform && terraform apply -var-file=terraform.tfvars

terraform-destroy: terraform-init
	@echo "$(CYAN)⚠️  Destroying infrastructure...$(RESET)"
	cd terraform && terraform destroy -var-file=terraform.tfvars

# Helm commands
helm-deploy: validate
	@echo "$(CYAN)Deploying with Helm...$(RESET)"
	helm upgrade --install coursey ./helm-charts/coursey-backend/ \
		-f helm-charts/coursey-backend/values.yaml \
		-f helm-charts/coursey-backend/values-local.yaml \
		--namespace default \
		--timeout 5m \
		--wait

helm-uninstall:
	@echo "$(CYAN)Uninstalling Helm release...$(RESET)"
	helm uninstall coursey --namespace default

# Cleanup
clean:
	@echo "$(CYAN)Cleaning up...$(RESET)"
	rm -rf terraform/.terraform
	rm -f terraform/.terraform.lock.hcl
	@echo "$(CYAN)✅ Cleanup complete$(RESET)"

# ==============================================================================
# AWS / Kubernetes Helpers
# ==============================================================================

# Get kubeconfig for EKS cluster
kubeconfig:
	@echo "$(CYAN)Updating kubeconfig...$(RESET)"
	@. ./.env 2>/dev/null || true; \
	aws eks update-kubeconfig --name $${EKS_CLUSTER_NAME:-my-eks-cluster} --region $${AWS_REGION:-us-east-1}
	@echo "$(CYAN)✅ Kubeconfig updated$(RESET)"

# Login to ECR
ecr-login:
	@echo "$(CYAN)Logging into ECR...$(RESET)"
	@. ./.env 2>/dev/null || true; \
	aws ecr get-login-password --region $${AWS_REGION:-us-east-1} | \
	docker login --username AWS --password-stdin $${AWS_ACCOUNT_ID:-$(shell aws sts get-caller-identity --query Account --output text)}.dkr.ecr.$${AWS_REGION:-us-east-1}.amazonaws.com
	@echo "$(CYAN)✅ ECR login successful$(RESET)"

# Build all Docker images
docker-build:
	@echo "$(CYAN)Building Docker images...$(RESET)"
	docker build -t coursey/php:latest -f back-end/php/Dockerfile back-end/
	docker build -t coursey/nginx:latest -f back-end/nginx/Dockerfile back-end/
	docker build -t coursey/mysql:latest -f back-end/mysql/Dockerfile back-end/
	docker build -t coursey/python:latest -f back-end/python/Dockerfile back-end/
	@echo "$(CYAN)✅ All images built$(RESET)"

# Push all Docker images to ECR
docker-push: ecr-login
	@echo "$(CYAN)Pushing images to ECR...$(RESET)"
	@. ./.env 2>/dev/null || true; \
	ECR_URI=$${AWS_ACCOUNT_ID:-$(shell aws sts get-caller-identity --query Account --output text)}.dkr.ecr.$${AWS_REGION:-us-east-1}.amazonaws.com; \
	for svc in php nginx mysql python; do \
		docker tag coursey/$$svc:latest $$ECR_URI/$${ECR_REPO_PREFIX:-coursey}/$$svc:latest && \
		docker push $$ECR_URI/$${ECR_REPO_PREFIX:-coursey}/$$svc:latest; \
	done
	@echo "$(CYAN)✅ All images pushed$(RESET)"

# View running pods
pods:
	kubectl get pods -A

# View logs for a specific pod
logs:
	@read -p "Enter pod name: " pod; kubectl logs -f $$pod
