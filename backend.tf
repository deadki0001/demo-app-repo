// For more information on how to secure your Terraform State you can vist the below link
// https://developer.hashicorp.com/terraform/language/backend/s3
// We are going to make use of State Locking, this will ensure that we protect the state by only allowing one user to make changes to your infrastructure at any given point of time


terraform {
  backend "s3" {
    bucket         = "deadki-terraform-nonprod-state-bucket"
    key            = "terraform-nonprod.tfstate"
    region         = "us-east-2" 
    encrypt        = true
    dynamodb_table = "terraform-state-lock"             
  }
}