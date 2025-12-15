# Prod Backend Configuration
terraform {
  backend "s3" {
    bucket         = "deadki-terraform-staginbg-uat-state-bucket"
    key            = "terraform-staging.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

