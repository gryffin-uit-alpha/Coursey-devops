# Coursey

**Coursey** is a web platform designed for real-time learning, where users can access courses and materials instantly and interactively.

![System Overview](img/main_page.png)

## System Overview

![System Overview](img/overview_system.png)

## Prerequisites (Manual Setup Required)

Before deploying, you must manually create the following AWS resources:

### 1. Domain & Route53 Hosted Zone

```bash
# Create a hosted zone for your domain (if not already exists)
aws route53 create-hosted-zone --name example.com --caller-reference $(date +%s)

# Note the Hosted Zone ID from the output (e.g., Z1234567890ABC)
# Update your domain registrar's nameservers to point to Route53
```

### 2. ACM Certificate (SSL/TLS)

```bash
# Request a wildcard certificate for your domain
aws acm request-certificate \
  --domain-name "*.example.com" \
  --subject-alternative-names "example.com" \
  --validation-method DNS \
  --region us-east-1

# Note the CertificateArn from the output!
# Add DNS validation record in Route53, then wait for validation
aws acm describe-certificate --certificate-arn <YOUR_CERT_ARN> --query 'Certificate.Status'
```

### 3. S3 Bucket for Frontend (Static Website)

```bash
# Create S3 bucket for frontend hosting
aws s3 mb s3://my-frontend-bucket --region us-east-1

# Enable static website hosting
aws s3 website s3://my-frontend-bucket --index-document index.html --error-document index.html
```

### 4. CloudFront Distribution (CDN)

1. Go to AWS Console → CloudFront → Create Distribution
2. Origin: Select your S3 bucket
3. Viewer Protocol Policy: Redirect HTTP to HTTPS
4. Alternate Domain Names (CNAMEs): `www.example.com`
5. SSL Certificate: Select your ACM certificate
6. Note the **Distribution ID** from the output

### 5. Terraform State Bucket (Optional but Recommended)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://my-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket my-terraform-state-bucket --versioning-configuration Status=Enabled
```

---

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
| `S3_BUCKET_NAME` | Frontend S3 bucket (from Prerequisites) | `my-frontend-bucket` |
| `DOMAIN_NAME` | Your domain name | `example.com` |

### 3. Configure GitHub Secrets

Add these secrets in **Settings > Secrets and variables > Secrets**:

| Secret | Description | Source |
|--------|-------------|--------|
| `AWS_ACCESS_KEY_ID` | AWS access key | IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | IAM Console |
| `GRAFANA_PASSWORD` | Grafana admin password | Create a secure password |
| `ACM_CERTIFICATE_ARN` | SSL certificate ARN | From Prerequisites Step 2 |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront ID | From Prerequisites Step 4 |
| `SONAR_HOST_URL` | SonarQube server URL | `https://sonarcloud.io` |
| `SONAR_TOKEN_BACKEND` | SonarQube backend token | SonarCloud → My Account |
| `SONAR_TOKEN_FRONTEND` | SonarQube frontend token | SonarCloud → My Account |

### 4. Deploy Infrastructure

```bash
# Plan and apply Terraform
make terraform-plan
make terraform-apply

# Deploy application (via CI/CD or manually - see below)
```

### 5. Manual Deployment (Optional)

If deploying manually without CI/CD, use Helm with `--set` flags to inject your configuration:

```bash
# Update kubeconfig
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1

# Deploy with your values
helm upgrade --install coursey ./helm-charts/coursey-backend/ \
  --namespace default \
  --set ingress.alb.certificateArn="arn:aws:acm:us-east-1:123456789:certificate/your-cert-id" \
  --set secrets.hostName="example.com" \
  --set appConfig.apiBaseUrl="https://api.example.com" \
  --set "ingress.hosts[0].host=api.example.com" \
  --set "ingress.hosts[1].host=admin.example.com" \
  --set php.image.repository="123456789.dkr.ecr.us-east-1.amazonaws.com/coursey/php" \
  --set nginx.image.repository="123456789.dkr.ecr.us-east-1.amazonaws.com/coursey/nginx" \
  --set mysql.image.repository="123456789.dkr.ecr.us-east-1.amazonaws.com/coursey/mysql" \
  --set python.image.repository="123456789.dkr.ecr.us-east-1.amazonaws.com/coursey/python" \
  --timeout 5m \
  --wait
```

**Key values to replace:**
| Placeholder | Your Value |
|-------------|------------|
| `arn:aws:acm:...` | Your ACM Certificate ARN |
| `example.com` | Your domain name |
| `123456789` | Your AWS Account ID |
| `us-east-1` | Your AWS Region |


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

