#!/bin/bash

echo "🚀 Deploying Coursey Frontend to S3..."

# Set environment
export NODE_ENV=production

# Navigate to frontend directory
cd front-end

# Install dependencies including devDependencies
echo "📦 Installing dependencies..."
npm install
npm install --save-dev eslint-plugin-storybook

# Build for production
echo "🔨 Building for production..."
npm run build

# Upload to S3 bucket
echo "☁️ Uploading to S3 bucket: coursey-project..."
aws s3 sync build/ s3://coursey-project --delete

# Configure S3 bucket for static website hosting
echo "🌐 Configuring S3 bucket for static website hosting..."
aws s3 website s3://coursey-project --index-document index.html --error-document index.html

# Set public read policy
echo "🔓 Setting bucket policy for public access..."
aws s3api put-bucket-policy --bucket coursey-project --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::coursey-project/*"
    }
  ]
}'

echo "✅ Frontend deployment complete!"
echo "🔗 Your frontend is accessible at: http://coursey-project.s3-website-us-east-1.amazonaws.com"