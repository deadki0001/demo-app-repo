# ============================================================================
# Terraform Provider Configuration
# ============================================================================
# This file configures the Terraform providers and required versions
# Providers are plugins that Terraform uses to interact with cloud platforms,
# SaaS providers, and other APIs
# ============================================================================

# -----------------------------------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------------------------------
# Specify required Terraform version and required providers

terraform {
  # Require Terraform 1.0 or newer
  required_version = ">= 1.0"

  # Configure required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use AWS provider version 5.x
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend configuration for state storage
  # This is configured dynamically via GitHub Actions workflow
  # using -backend-config flags during terraform init
  backend "s3" {
    # bucket         = "configured-via-workflow"
    # key            = "configured-via-workflow"
    # region         = "configured-via-workflow"
    # dynamodb_table = "configured-via-workflow"
    encrypt = true
  }
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------------------------------
# Configure the AWS provider with default settings
# Authentication is handled via:
# - GitHub Actions: OIDC (no static credentials)
# - Local development: AWS CLI credentials or environment variables

provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources created by this provider
  # These tags help with cost allocation, resource management, and compliance
  default_tags {
    tags = merge(
      var.common_tags,
      {
        Environment = var.environment
        Terraform   = "true"
      }
    )
  }
}

# -----------------------------------------------------------------------------
# TLS Provider Configuration
# -----------------------------------------------------------------------------
# Used for generating TLS certificates and reading OIDC thumbprints

provider "tls" {
  # No configuration needed - uses defaults
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
# Data sources allow Terraform to fetch information about existing resources
# or compute values based on the current AWS account/region

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Get available availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Local values are computed values that can be used throughout the configuration
# They're useful for deriving values or avoiding repetition

locals {
  # Current AWS account ID
  account_id = data.aws_caller_identity.current.account_id

  # Current AWS region
  region = data.aws_region.current.name

  # Common name prefix for resources
  name_prefix = "${var.environment}-demo"

  # Availability zones to use (first 2 in the region)
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Common resource tags
  common_resource_tags = {
    Project     = "Demo Application"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Region      = local.region
    AccountId   = local.account_id
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
# Output values that might be useful for debugging or reference

output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "region" {
  description = "AWS Region"
  value       = local.region
}

output "availability_zones" {
  description = "Availability zones being used"
  value       = local.azs
}
