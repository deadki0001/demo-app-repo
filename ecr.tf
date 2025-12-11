# Amazon ECR Repository for Container Images
# Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources

# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR repository encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "ecr-encryption-key"
    Environment = "multi-environment"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr-demo-app-images"
  target_key_id = aws_kms_key.ecr.key_id
}

# checkov:skip=CKV_AWS_51:MUTABLE tags required for demo/dev workflow - allows retagging images
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