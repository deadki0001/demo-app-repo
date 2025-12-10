# Prod Backend Configuration
terraform {
  backend "s3" {
    bucket         = "deadki-terraform-production-state-bucket"
    key            = "terraform-prod.tfstate"
    region         = "us-east-2" 
    encrypt        = true
    dynamodb_table = "terraform-state-lock"             
  }
}
