# Kubernetes Deployment Guide

## Domain Configuration: gryffin-uit.site

## Changes Made for Production Deployment

### 1. Frontend Changes (Now hosted on S3)
- **File**: `front-end/src/config/env.js`
  - Updated production URL to use `https://gryffin-uit.site`
- **File**: `front-end/.env.production`
  - Set `REACT_APP_API_URL=https://gryffin-uit.site`
- **File**: `front-end/aws/deploy-to-s3.sh`
  - Created S3 deployment script
- **Removed**: Frontend Kubernetes deployment (now hosted on S3)

### 2. Backend Admin Panel Changes
- **Files**: All admin panel HTML files (`addCourse.html`, `users.html`, `course.html`, `login.html`, `addHost.html`, `addLecturer.html`)
  - Replaced hardcoded `http://localhost:8080` with `${window.API_BASE_URL || 'http://localhost:8080'}`
  - Added `api-config.js` script inclusion
- **File**: `back-end/app/public/adminpanel/api-config.js`
  - Created API configuration file for dynamic URL setting

### 3. Nginx Configuration Changes
- **File**: `back-end/nginx/conf.d/default.conf`
  - Changed `fastcgi_pass` from `app:9000` to `php-service:9000`
  - Updated server_name from `localhost` to `_` (wildcard)

### 4. Environment Variables
- **File**: `back-end/.env/.env`
  - Updated `HOST_NAME` to `gryffin-uit.site`
- **File**: `kuberdef/secret.yaml`
  - Updated `HOST_NAME` base64 value to `gryffin-uit.site`
- **File**: `kuberdef/coursey-ingress.yaml`
  - Updated host to `gryffin-uit.site`
  - Added TLS/SSL configuration

### 5. Kubernetes Resources
- **ConfigMaps**:
  - `backend-configmap.yaml`: Backend API configuration (updated for domain)
- **SSL/TLS**:
  - `cert-manager-issuer.yaml`: Let's Encrypt SSL certificate issuer
- **Updated Deployments**:
  - `php-deployment.yaml`: Added HOST_NAME environment variable
  - `nginx-deployment.yaml`: Added ConfigMap volume mount
  - `coursey-ingress.yaml`: Added TLS configuration and domain

### 6. Service Communication Mapping

| Frontend Access | Backend API | Purpose |
|-----------------|-------------|---------|
| S3 Static Website | `https://gryffin-uit.site` | Main application API |
| S3 Static Website | `https://gryffin-uit.site/admin` | Admin panel |
| Internal | `db:3306` | Database connection |
| Internal | `python-service:8002` | Python admin backend |

## Deployment Steps

### Backend Deployment (Kubernetes)

1. **Install cert-manager** (if not already installed):
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

2. **Apply SSL Certificate Issuer**:
   ```bash
   kubectl apply -f kuberdef/cert-manager-issuer.yaml
   ```

3. **Apply ConfigMaps**:
   ```bash
   kubectl apply -f kuberdef/backend-configmap.yaml
   ```

2. **Apply Secrets**:
   ```bash
   kubectl apply -f kuberdef/secret.yaml
   ```

3. **Deploy Database**:
   ```bash
   kubectl apply -f kuberdef/databasepvc.yaml
   kubectl apply -f kuberdef/database-deployment.yaml
   kubectl apply -f kuberdef/database-service.yaml
   ```

4. **Deploy Backend Services**:
   ```bash
   kubectl apply -f kuberdef/php-deployment.yaml
   kubectl apply -f kuberdef/php-service.yaml
   kubectl apply -f kuberdef/python-deployment.yaml
   kubectl apply -f kuberdef/python-service.yaml
   ```

5. **Deploy Nginx**:
   ```bash
   kubectl apply -f kuberdef/nginx-deployment.yaml
   kubectl apply -f kuberdef/nginx-service.yaml
   ```

6. **Apply Ingress**:
   ```bash
   kubectl apply -f kuberdef/coursey-ingress.yaml
   ```

### Frontend Deployment (AWS S3)

1. **Configure AWS CLI**:
   ```bash
   aws configure
   ```

2. **Create S3 bucket**:
   ```bash
   aws s3 mb s3://gryffin-uit-frontend
   ```

3. **Deploy frontend**:
   ```bash
   cd front-end
   ./aws/deploy-to-s3.sh production gryffin-uit-frontend
   ```

## Verification

1. **Check all pods are running**:
   ```bash
   kubectl get pods
   ```

2. **Check services**:
   ```bash
   kubectl get services
   ```

3. **Test internal connectivity**:
   ```bash
   kubectl exec -it <nginx-pod> -- nslookup php-service
   kubectl exec -it <php-pod> -- nslookup db
   ```

## Notes

- All hardcoded localhost references have been replaced with Kubernetes service names
- Environment variables are properly injected via ConfigMaps and Secrets
- Services can communicate using their Kubernetes service names
- The ingress provides external access to the application
- Admin panel now uses dynamic API URLs that work in both local and Kubernetes environments