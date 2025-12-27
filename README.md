# Coursey

**Coursey** is a web platform designed for real-time learning, where users can access courses and materials instantly and interactively.

![System Overview](img/main_page.png)

## System Overview

![System Overview](img/overview_system.png)

## Quick Start

### 1. Initialize Configuration

```bash
# Clone the repository
git clone https://github.com/your-org/Coursey.git
cd Coursey

# Initialize configuration files from templates
make init
```

This creates the following files that you must configure:
- `.env` - Environment variables
- `terraform/terraform.tfvars` - Terraform variables  
- `terraform/backend.hcl` - Terraform state backend
- `helm-charts/coursey-backend/values-local.yaml` - Helm values

### 2. Configure GitHub Repository Variables

Go to your GitHub repository **Settings > Secrets and variables > Variables** and add:

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `us-east-1` |
| `EKS_CLUSTER_NAME` | EKS cluster name | `my-eks-cluster` |
| `ECR_REPO_PREFIX` | ECR repository prefix | `coursey` |
| `S3_BUCKET_NAME` | Frontend S3 bucket | `my-frontend-bucket` |
| `DOMAIN_NAME` | Your domain name | `example.com` |

### 3. Configure GitHub Secrets

Add these secrets in **Settings > Secrets and variables > Secrets**:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `GRAFANA_PASSWORD` | Grafana admin password |
| `SONAR_HOST_URL` | SonarQube server URL |
| `SONAR_TOKEN_BACKEND` | SonarQube backend token |
| `SONAR_TOKEN_FRONTEND` | SonarQube frontend token |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID |

### 4. Create AWS ACM Certificate

Before deploying, you need an SSL certificate for HTTPS:

```bash
# Request a certificate (replace with your domain)
aws acm request-certificate \
  --domain-name "*.example.com" \
  --subject-alternative-names "example.com" \
  --validation-method DNS \
  --region us-east-1

# Note the CertificateArn from the output!
# Add DNS validation record in Route53, then wait for validation
```

Copy the **Certificate ARN** to your Helm values file:
```yaml
# helm-charts/coursey-backend/values-local.yaml
ingress:
  alb:
    certificateArn: "arn:aws:acm:us-east-1:123456789:certificate/abc-123..."
```

### 5. Deploy Infrastructure

```bash
# Plan and apply Terraform
make terraform-plan
make terraform-apply

# Deploy application
make helm-deploy
```

## Local Development

### Frontend

```bash
cd front-end
npm install
npm start
# Access at http://localhost:3000
```

### Backend

```bash
cd back-end
cp .env.example .env   # Edit .env with your database credentials
docker compose up --build
# API at http://localhost:8080, Admin at http://localhost:8082
```

### Database Setup

```bash
docker exec -i back-end-db-1 mysql -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE < back-end/sql/docker-php_export.sql
```

> **Note:** Default credentials are configured in your local `.env` file. Never commit actual credentials to version control.

## Available Commands

Run `make help` to see all available commands:

```
Coursey DevOps Commands
========================

Setup:
  make init              - Initialize project (copy example config files)
  make validate          - Validate configuration files exist

Terraform:
  make terraform-init    - Initialize Terraform with backend config
  make terraform-plan    - Run Terraform plan
  make terraform-apply   - Apply Terraform changes
  make terraform-destroy - Destroy infrastructure

Helm:
  make helm-deploy       - Deploy application via Helm
  make helm-uninstall    - Uninstall Helm release

Cleanup:
  make clean             - Clean up local Terraform files
```

## Contributing

We welcome contributions to Coursey. Please submit a pull request with your changes.

## License

Coursey is licensed under the [MIT License](https://opensource.org/licenses/MIT).

