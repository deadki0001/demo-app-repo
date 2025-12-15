# ============================================================================
# Terraform Provider Configuration
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend is configured in backend.tf
}

# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "Demo Application"
    }
  }
}

# -----------------------------------------------------------------------------
# TLS Provider
# -----------------------------------------------------------------------------
provider "tls" {}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  name_prefix = "${var.environment}-demo"

  common_tags = {
    Project     = "Demo Application"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
