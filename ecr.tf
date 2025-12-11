# Amazon ECR Repository for Container Images
# Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources

# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR repository encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  # Explicit key policy for Checkov compliance
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "ecr-encryption-key"
    Environment = "multi-environment"
    ManagedBy   = "Terraform"
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr-demo-app-images"
  target_key_id = aws_kms_key.ecr.key_id
}

#checkov:skip=CKV_AWS_51:MUTABLE tags required for demo/dev workflow - allows pushing nonprod-latest, staging-latest tags
resource "aws_ecr_repository" "demo_ecr_repo" {
  name                 = "demo-app-images"
  image_tag_mutability = "MUTABLE" # For demo - allows pushing same tags (nonprod-latest, etc)

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = {
    Name        = "demo-app-images"
    Environment = "multi-environment"
    ManagedBy   = "Terraform"
  }
}

# Lifecycle policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "demo_ecr_lifecycle" {
  repository = aws_ecr_repository.demo_ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-", "staging-", "nonprod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Output the repository URL
output "ecr_repository_url" {
  value       = aws_ecr_repository.demo_ecr_repo.repository_url
  description = "ECR Repository URL for pushing images"
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.demo_ecr_repo.arn
  description = "ECR Repository ARN"
}