# Coursey - Real-Time Learning Platform

**Coursey** is a modern web platform designed for real-time learning. It enables users to browse, access, and interact with courses and educational materials instantly and interactively.

![System Overview](img/main_page.png)

## 📌 Project Overview

This repository contains the source code and Infrastructure as Code (IaC) configurations for deploying the entire Coursey ecosystem. The project is designed with a microservices-oriented backend, a modern frontend, and a fully automated deployment lifecycle targetting self-hosted/cloud-native environments using Kubernetes.

![System Architecture](img/overview_system.png)

## 🛠️ Technology Stack & Architecture

The project leverages a robust and modern technology stack to ensure scalability, maintainability, and high availability.

### 🌐 Frontend (Web App)
- **Framework:** React.js / SCSS
- **Hosting:** Amazon S3 & CloudFront (CDN)

### ⚙️ Backend (Microservices Core)
- **API Gateway / Proxy:** Nginx (Routing requests)
- **Core Services:** PHP (Primary Business Logic)
- **Data Science/AI Services:** Python (FastAPI/Flask)
- **Database:** MySQL (Relational Data Storage)

### ☁️ Infrastructure & Orchestration
- **Cloud Provider:** Amazon Web Services (AWS)
- **Containerization:** Docker & Amazon Elastic Container Registry (ECR)
- **Orchestration:** Kubernetes (Amazon EKS)
- **Infrastructure as Code (IaC):** Terraform
- **Package Management:** Helm Charts

### 🔍 Monitoring & Security
- **Monitoring & Observability:** Prometheus & Grafana
- **Log Management:** Fluent Bit & Amazon CloudWatch
- **Code Quality:** SonarQube (Static Analysis)
- **Vulnerability Scanning:** Trivy (Container Security)


## 🚀 Automated CI/CD Pipelines

![CI/CD Pipeline](img/cicd-pipeline.png)

The project utilizes **GitHub Actions** to fully automate integration and delivery across three distinct pipelines:

   1. **Infrastructure Pipeline (`IaC.yml`)**
   - Automatically provisions and updates AWS resources (VPC, Subnets, EKS, ALB Controller, ExternalDNS, CloudWatch Logs, RDS) using Terraform.
   - Enforces infrastructure changes safely via `terraform plan` on PRs and `terraform apply` on main branch merges.

2. **Continuous Integration Pipeline (`ci.yml`)**
   - Consolidated CI for both Frontend and Backend for unified quality control.
   - **Backend:** Implements intelligent path filtering (only rebuilds changed services), utilizes Docker Buildx caching, and performs Trivy security scans.
   - **Frontend:** Builds optimized React static bundles and uploads them as secure GitHub artifacts.
   - **Quality Gate:** Mandatory SonarQube analysis for both Frontend and Backend codebases.

3. **Continuous Deployment Pipeline (`cd.yml`)**
   - Decoupled from CI to follow the principle of least privilege and controlled releases.
   - **Trigger:** Automatically invoked upon successful completion of the CI pipeline on the `main` branch.
   - **Backend:** Performs atomic `helm upgrade` to deploy microservices into the EKS cluster.
   - **Frontend:** Downloads build artifacts from CI, syncs them to S3, and invalidates CloudFront CDN for instant global updates.

---

## 🛠️ Current Limitations & Future Roadmap

While the current architecture is robust, there are areas identified for further optimization as the platform scales:

- **Secret Management (Highest Priority):** Currently, application secrets (DB credentials, API keys) are managed via **GitHub Secrets** and injected during the CD process. To align with enterprise-grade security standards (Zero Trust), the next phase involves migrating to:
    - **AWS Secrets Manager:** For seamless, automated rotation of RDS credentials.
    - **HashiCorp Vault:** To implement dynamic secrets and unified secret management across cloud and on-premise environments.
- **Auto-sharding Database:** As the user base grows, exploring RDS Aurora for automated scaling and read replicas.


---

## 📖 Deployment & Contribution Guide

For full, step-by-step instructions on deploying the infrastructure, setting up local development, and tearing down the environment, please refer to the **deployment instruction PDF document** provided alongside this repository.

### License
Coursey is licensed under the [MIT License](https://opensource.org/licenses/MIT).
