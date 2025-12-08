// https://registry.terraform.io/providers/hashicorp/aws/latest/docs
// The above link contains more details on Terraform Providers.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}