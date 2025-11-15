#!/bin/bash

echo "🚀 Deploying Coursey Backend Services..."

# Step 1: Deploy secrets and config
echo "📋 Deploying secrets and configuration..."
kubectl apply -f kuberdef/secret.yaml
kubectl apply -f kuberdef/backend-configmap.yaml

# Step 2: Deploy database
echo "🗄️ Deploying database..."
kubectl apply -f kuberdef/databasepvc.yaml
kubectl apply -f kuberdef/database-deployment.yaml
kubectl apply -f kuberdef/database-service.yaml

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=coursey-database --timeout=300s

# Step 3: Deploy application services
echo "🔧 Deploying application services..."
kubectl apply -f kuberdef/php-deployment.yaml
kubectl apply -f kuberdef/php-service.yaml
kubectl apply -f kuberdef/python-deployment.yaml
kubectl apply -f kuberdef/python-service.yaml
kubectl apply -f kuberdef/nginx-deployment.yaml
kubectl apply -f kuberdef/nginx-service.yaml

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=coursey-php --timeout=300s
kubectl wait --for=condition=ready pod -l app=coursey-python --timeout=300s
kubectl wait --for=condition=ready pod -l app=coursey-nginx --timeout=300s

# Step 4: Deploy ingress
echo "🌐 Deploying ingress..."
kubectl apply -f kuberdef/coursey-ingress.yaml

echo "✅ Backend deployment complete!"
echo "📊 Checking status..."
kubectl get pods
kubectl get services
kubectl get ingress

echo "🔗 Your application should be accessible at: https://gryffin-uit.site"