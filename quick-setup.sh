#!/bin/bash
# Quick 30-minute setup for Luno interview demo
# Run this in your demo-app-repo directory

set -e

echo "🚀 Luno Interview Demo - Quick Setup"
echo "======================================"

# 1. Create eks.tf file
echo "📝 Creating eks.tf..."
cat > eks.tf << 'EOF'
# See artifact: eks_terraform
EOF

# 2. Create k8s directory and manifests
echo "📁 Creating k8s directory..."
mkdir -p k8s

cat > k8s/deployment.yaml << 'EOF'
# See artifact: k8s_deployment
EOF

# 3. Update provider.tf region
echo "🔧 Updating provider region..."
sed -i 's/region = "us-east-2"/region = "us-east-2"/' provider.tf

# 4. Update backend.tf region if needed
echo "🔧 Checking backend configuration..."
grep -q "us-east-2" backend.tf || echo "⚠️  WARNING: backend.tf still uses us-east-2"

# 5. Update outputs.tf
echo "📝 Updating outputs.tf..."
cat >> outputs.tf << 'EOF'

output "eks_cluster_name" {
  value       = aws_eks_cluster.demo.name
  description = "EKS Cluster Name"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.demo.endpoint
  description = "EKS Cluster Endpoint"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.demo_ecr_repo.repository_url
  description = "ECR Repository URL"
}
EOF

# 6. Comment out EC2 instance (we're using EKS now)
echo "💤 Commenting out EC2 instance..."
if grep -q "^resource \"aws_instance\"" elastic-compute.tf; then
    sed -i 's/^resource "aws_instance"/# resource "aws_instance"/' elastic-compute.tf
    echo "✅ EC2 instance commented out"
fi

# 7. Format Terraform
echo "🎨 Formatting Terraform files..."
terraform fmt

# 8. Validate configuration
echo "✅ Validating Terraform..."
terraform validate

# 9. Create GitHub workflow directory
echo "📁 Creating GitHub workflows..."
mkdir -p .github/workflows

# Copy your existing workflows and update them
# For now, just show what needs to be done
cat << 'INSTRUCTIONS'

📋 MANUAL STEPS REQUIRED:
========================

1. GitHub Branch Protection (5 mins):
   - Go to: https://github.com/YOUR_ORG/YOUR_REPO/settings/branches
   - Add rule for 'main' branch:
     ☑ Require pull request (2 approvals)
     ☑ Require status checks (security-scan-iac, terraform-plan)
     ☑ Require conversation resolution
     ☑ No force pushes
     ☑ No deletions

2. GitHub Repository Variables (2 mins):
   Settings → Secrets and variables → Actions → Variables
   
   Add these:
   - AWS_ROLE_ARN_PROD: arn:aws:iam::ACCOUNT:role/GitHubActionsRole-Prod
   - AWS_ROLE_ARN_STAGING: arn:aws:iam::ACCOUNT:role/GitHubActionsRole-Staging
   - AWS_ROLE_ARN_NONPROD: arn:aws:iam::ACCOUNT:role/GitHubActionsRole-NonProd
   - TF_STATE_BUCKET_PROD: your-prod-state-bucket
   - TF_STATE_BUCKET_STAGING: your-staging-state-bucket
   - TF_STATE_BUCKET_NONPROD: your-nonprod-state-bucket
   - TF_STATE_LOCK_TABLE: terraform-state-lock
   - AWS_REGION: us-east-2

3. GitHub Environments (3 mins):
   Settings → Environments → New environment
   
   Create:
   - 'production' (require 2 reviewers)
   - 'staging' (require 1 reviewer)
   - 'production-destroy' (require 2 reviewers)

4. Update workflows (5 mins):
   - Copy the updated workflow from artifact to:
     .github/workflows/deployment-prod-pipeline.yml

5. Test locally (10 mins):
   terraform init
   terraform plan
   
   # If plan looks good:
   terraform apply -auto-approve

6. Configure kubectl (2 mins):
   aws eks update-kubeconfig --region us-east-2 --name demo-eks-cluster
   kubectl get nodes
   kubectl get pods -A

7. Deploy app to EKS (3 mins):
   # Update k8s/deployment.yaml with your ECR URL
   export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   sed -i "s/ACCOUNT_ID/$ACCOUNT_ID/g" k8s/deployment.yaml
   
   kubectl create namespace demo-app
   kubectl apply -f k8s/ -n demo-app
   kubectl get svc -n demo-app

INSTRUCTIONS

echo ""
echo "✅ Automated setup complete!"
echo "📋 Follow the manual steps above"
echo ""
echo "⏱️  Time breakdown:"
echo "   - Automated: 5 mins"
echo "   - Manual GitHub setup: 10 mins"
echo "   - Terraform apply: 10 mins"
echo "   - Testing: 5 mins"
echo "   = Total: ~30 mins"
echo ""
echo "🎯 For interview demo:"
echo "   1. Show branch protection blocking direct push"
echo "   2. Show OIDC workflow with no stored credentials"
echo "   3. Show security scans failing/passing"
echo "   4. Show EKS cluster running app"
echo "   5. Explain: No static creds, multi-stage security, GitOps ready"