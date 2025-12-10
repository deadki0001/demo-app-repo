# #!/bin/bash
# apt-get update -y
# apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq unzip

# # Install Docker
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# apt-get update -y
# apt-get install -y docker-ce
# systemctl enable docker
# systemctl start docker

# # Install AWS CLI v2
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# ./aws/install

# # Define DB variables from Terraform
# DB_HOST="${DB_HOST}"
# DB_NAME="${DB_NAME}"
# DB_USER="${DB_USER}"

# # Get AWS Account ID
# AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# AWS_REGION="us-east-2"

# # Get RDS password from AWS Secrets Manager
# SECRET_ARN=$(aws rds describe-db-instances --db-instance-identifier demo-database --query 'DBInstances[0].MasterUserSecret.SecretArn' --output text)

# for i in {1..5}; do
#   DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text 2>/dev/null | jq -r '.password')
#   if [ -n "$DB_PASSWORD" ]; then
#     break
#   fi
#   sleep 10
# done


# # Login to ECR
# aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-2.amazonaws.com

# # Run the container
# docker run -d -p 80:80 \
#   -e DB_HOST="$DB_HOST" \
#   -e DB_NAME="$DB_NAME" \
#   -e DB_USER="$DB_USER" \
#   -e DB_PASSWORD="$DB_PASSWORD" \
#   $AWS_ACCOUNT_ID.dkr.ecr.us-east-2.amazonaws.com/demo-app-images:latest
