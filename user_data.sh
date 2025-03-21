#!/bin/bash
set -e  # Exit on any error

# Update system and install required packages
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq unzip

# Install Docker properly
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce
systemctl enable docker
systemctl start docker

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws

# Set environment variables from Terraform interpolation
DB_HOST="${DB_HOST}"
DB_NAME="${DB_NAME}"
DB_USER="admin"

# Detect AWS region dynamically
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Retry loop for AWS commands to ensure instance is fully initialized
for i in {1..5}; do
  SECRET_ARN=$(aws rds describe-db-instances --db-instance-identifier demo-database --query 'DBInstances[0].MasterUserSecret.SecretArn' --output text 2>/dev/null) && break
  sleep 10
done

# Retrieve RDS password from AWS Secrets Manager
for i in {1..5}; do
  DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text 2>/dev/null | jq -r '. | fromjson | .password') && break
  sleep 10
done

# Login to AWS ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Create startup script
cat > /root/start-container.sh <<'SCRIPT'
#!/bin/bash
export PATH=$PATH:/usr/local/bin

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Run Docker container
docker run -d -p 80:80 \
  -e DB_HOST="${DB_HOST}" \
  -e DB_NAME="${DB_NAME}" \
  -e DB_USER="${DB_USER}" \
  -e DB_PASSWORD="${DB_PASSWORD}" \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/demo-app-images:latest"
SCRIPT

chmod +x /root/start-container.sh

# Schedule script to run at startup with a delay
echo "@reboot sleep 120 && /root/start-container.sh > /root/container-startup.log 2>&1" | crontab -

# Run the script immediately after a delay (in case setup is already complete)
nohup bash -c "sleep 120 && /root/start-container.sh > /root/container-startup.log 2>&1" &
