// Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.
// For a more ind depth read on Amazon ECR, I have included a readme.txt with the AWS Whitepaper which will provide you with any additional context.

resource "aws_kms_key" "ecr_kms" {
  description             = "KMS key for ECR encryption (nonprod)"
  deletion_window_in_days = 7
}

resource "aws_ecr_repository" "demo_ecr_repo" {
  name                 = "demo-app-images"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_kms.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
