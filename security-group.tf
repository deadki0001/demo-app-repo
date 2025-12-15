# ============================================================================
# Security Groups Configuration
# ============================================================================
# This file defines security groups for various components:
# - Application Load Balancer (ALB)
# - EC2 instances (if used)
# - RDS database
# - General application security groups
# ============================================================================

# AWS Security Groups documentation: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html
# Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# -----------------------------------------------------------------------------
# Application Load Balancer Security Group
# -----------------------------------------------------------------------------
# This security group controls traffic to/from the Application Load Balancer
# ALB receives traffic from the internet and forwards to application instances

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.demo_application_vpc.id

  # Inbound Rules (Ingress)

  # Allow HTTP traffic from anywhere
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules (Egress)

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Application Load Balancer"
  }
}

# -----------------------------------------------------------------------------
# Application/Web Server Security Group
# -----------------------------------------------------------------------------
# This security group is for EC2 instances running your application
# It allows traffic from the load balancer and other necessary sources

resource "aws_security_group" "application" {
  name        = "${var.environment}-application-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.demo_application_vpc.id

  # Inbound Rules (Ingress)

  # Allow HTTP from ALB
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow HTTPS from ALB
  ingress {
    description     = "Allow HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow custom application port (e.g., Node.js, Flask, Spring Boot)
  ingress {
    description     = "Allow application port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow SSH from within VPC (for management)
  # In production, restrict this further or use AWS Systems Manager Session Manager
  ingress {
    description = "Allow SSH from within VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.demo_application_vpc.cidr_block]
  }

  # Outbound Rules (Egress)

  # Allow all outbound traffic
  # Application needs to reach internet for updates, external APIs, etc.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-application-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Application Servers"
  }
}

# -----------------------------------------------------------------------------
# RDS Database Security Group
# -----------------------------------------------------------------------------
# This security group controls access to the RDS database
# Only allow connections from application servers, not from the internet

resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.demo_application_vpc.id

  # Inbound Rules (Ingress)

  # Allow MySQL/MariaDB from application servers
  ingress {
    description     = "Allow MySQL from application servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Allow MySQL from EKS worker nodes (if using EKS)
  ingress {
    description     = "Allow MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
  }

  # PostgreSQL alternative (uncomment if using PostgreSQL instead of MySQL)
  # ingress {
  #   description     = "Allow PostgreSQL from application servers"
  #   from_port       = 5432
  #   to_port         = 5432
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.application.id]
  # }

  # Outbound Rules (Egress)

  # Databases typically don't need outbound internet access
  # But we allow it here for flexibility (e.g., extensions, replication)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-database-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "RDS Database"
  }
}

# -----------------------------------------------------------------------------
# Bastion Host Security Group (Optional)
# -----------------------------------------------------------------------------
# If you need a bastion host for SSH access to private resources
# Uncomment this section if needed

# resource "aws_security_group" "bastion" {
#   name        = "${var.environment}-bastion-sg"
#   description = "Security group for bastion host"
#   vpc_id      = aws_vpc.demo_application_vpc.id
#
#   # Allow SSH from specific IP addresses only
#   # Replace with your office/home IP or VPN IP
#   ingress {
#     description = "Allow SSH from trusted IPs"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = var.allowed_cidr_blocks # Define this in variables.tf
#   }
#
#   # Allow outbound to anywhere for SSH forwarding
#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name        = "${var.environment}-bastion-sg"
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Purpose     = "Bastion Host"
#   }
# }

# -----------------------------------------------------------------------------
# Redis/ElastiCache Security Group (Optional)
# -----------------------------------------------------------------------------
# If you're using Redis or ElastiCache for caching
# Uncomment this section if needed

# resource "aws_security_group" "redis" {
#   name        = "${var.environment}-redis-sg"
#   description = "Security group for Redis/ElastiCache"
#   vpc_id      = aws_vpc.demo_application_vpc.id
#
#   # Allow Redis from application servers
#   ingress {
#     description     = "Allow Redis from application servers"
#     from_port       = 6379
#     to_port         = 6379
#     protocol        = "tcp"
#     security_groups = [aws_security_group.application.id]
#   }
#
#   # Allow Redis from EKS nodes
#   ingress {
#     description     = "Allow Redis from EKS nodes"
#     from_port       = 6379
#     to_port         = 6379
#     protocol        = "tcp"
#     security_groups = [aws_security_group.eks_nodes_sg.id]
#   }
#
#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name        = "${var.environment}-redis-sg"
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Purpose     = "Redis Cache"
#   }
# }

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
# Export security group IDs for use in other resources

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# -----------------------------------------------------------------------------
# Security Best Practices (Comments)
# -----------------------------------------------------------------------------
# 1. PRINCIPLE OF LEAST PRIVILEGE:
#    - Only open ports that are absolutely necessary
#    - Restrict source IPs as much as possible
#    - Use security group references instead of CIDR blocks when possible
#
# 2. LAYERED SECURITY:
#    - ALB in public subnet (internet-facing)
#    - Application servers in private subnet (ALB access only)
#    - Database in private subnet (application access only)
#
# 3. REGULAR AUDITS:
#    - Review security group rules periodically
#    - Remove unused rules
#    - Update source IPs when they change
#
# 4. MONITORING:
#    - Enable VPC Flow Logs to monitor network traffic
#    - Set up CloudWatch alarms for unusual traffic patterns
#    - Use AWS Security Hub for compliance checks
#
# 5. ENCRYPTION:
#    - Use HTTPS/TLS for all external traffic
#    - Encrypt database connections
#    - Use AWS Certificate Manager for SSL/TLS certificates
