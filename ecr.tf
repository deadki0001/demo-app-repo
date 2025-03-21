resource "aws_ecr_repository" "demo_ecr_repo" {
  name                 = "demo-app-images"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}