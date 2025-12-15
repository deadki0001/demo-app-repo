# ============================================================================
# Terraform Variables
# ============================================================================
# This file defines all input variables used across the Terraform configuration
# Variables can be set via:
# - terraform.tfvars file
# - Environment variables (TF_VAR_name)
# - Command line flags (-var="name=value")
# - GitHub Actions workflow (via env vars)
# ============================================================================

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (nonprod, staging, prod)"
  type        = string
  default     = "nonprod"

  validation {
    condition     = contains(["nonprod", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: nonprod, staging, prod"
  }
}

# -----------------------------------------------------------------------------
# AWS Region Configuration
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

# -----------------------------------------------------------------------------
# Domain Configuration (for Route53)
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Root domain name for Route53 hosted zone"
  type        = string
  default     = "deadkithedeveloper.click"
}

# -----------------------------------------------------------------------------
# Tagging Configuration
# -----------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project    = "Demo Application"
    ManagedBy  = "Terraform"
    Repository = "demo-app-repo"
  }
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network traffic analysis"
  type        = bool
  default     = false # Set to true in production
}

# -----------------------------------------------------------------------------
# EKS Configuration
# -----------------------------------------------------------------------------

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "List of EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "eks_node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

# -----------------------------------------------------------------------------
# ECR Configuration
# -----------------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "demo-app-images"
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ECR image tag mutability must be either MUTABLE or IMMUTABLE"
  }
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push to ECR"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# RDS Configuration (if using MySQL)
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "demodb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false # Set to true in production
}

# -----------------------------------------------------------------------------
# Load Balancer Configuration
# -----------------------------------------------------------------------------

variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancers"
  type        = bool
  default     = false # Set to true in production
}

# -----------------------------------------------------------------------------
# Monitoring and Logging
# -----------------------------------------------------------------------------

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be a valid retention period"
  }
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production!
}

# -----------------------------------------------------------------------------
# Cost Optimization
# -----------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (costs ~$32/month per AZ)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway instead of one per AZ (cost savings but less HA)"
  type        = bool
  default     = true # Set to false in production for high availability
}
