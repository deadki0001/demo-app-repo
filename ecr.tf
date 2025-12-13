// Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.
// For a more ind depth read on Amazon ECR, I have included a readme.txt with the AWS Whitepaper which will provide you with any additional context.

resource "aws_ecr_repository" "demo_ecr_repo" {
  name                 = "demo-app-images"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
