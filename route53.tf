# # ============================================================================
# # Route53 & ACM Configuration - Multi-Environment Setup
# # ============================================================================
# # Domain: deadkithedeveloper.click
# # 
# # Environment Subdomains:
# #   - Production:  deadkithedeveloper.click (or www.deadkithedeveloper.click)
# #   - Staging:     staging.deadkithedeveloper.click  
# #   - NonProd:     nonprod.deadkithedeveloper.click
# # ============================================================================

# # -----------------------------------------------------------------------------
# # Variables
# # -----------------------------------------------------------------------------
# variable "environment" {
#   description = "Environment name (prod, staging, nonprod)"
#   type        = string
#   default     = "nonprod"
# }

# variable "domain_name" {
#   description = "Root domain name"
#   type        = string
#   default     = "deadkithedeveloper.click"
# }
#
# # -----------------------------------------------------------------------------
# # Local Variables
# # -----------------------------------------------------------------------------
# locals {
#   # Map environment to subdomain
#   subdomain_prefixes = {
#     prod    = ""        # Root domain
#     staging = "staging"
#     nonprod = "nonprod"
#   }

#   # Full domain for this environment
#   environment_domain = local.subdomain_prefixes[var.environment] == "" ? var.domain_name : "${local.subdomain_prefixes[var.environment]}.${var.domain_name}"
# }

# # -----------------------------------------------------------------------------
# # Route53 Hosted Zone
# # IMPORTANT: Create this ONLY ONCE in production account
# # Then export the zone_id to use in other environments
# # -----------------------------------------------------------------------------
# resource "aws_route53_zone" "main" {
#   count   = var.environment == "prod" ? 1 : 0  # Only create in prod
#   name    = var.domain_name
#   comment = "Managed by Terraform - Main hosted zone for ${var.domain_name}"

#   tags = {
#     Name        = var.domain_name
#     Environment = "shared"
#     ManagedBy   = "Terraform"
#     Purpose     = "Multi-environment DNS"
#   }
# }

# # -----------------------------------------------------------------------------
# # Data source for existing hosted zone (for non-prod environments)
# # Use this in staging/nonprod to reference the zone created in prod
# # -----------------------------------------------------------------------------
# data "aws_route53_zone" "existing" {
#   count = var.environment != "prod" ? 1 : 0
#   name  = var.domain_name
# }

# locals {
#   # Use the created zone in prod, or the data source in other envs
#   zone_id = var.environment == "prod" ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
# }

# # -----------------------------------------------------------------------------
# # ACM Certificate (Wildcard)
# # IMPORTANT: Create this ONLY ONCE in production account (us-east-1 for CloudFront)
# # For ALB in other regions, you'll need regional certificates
# # -----------------------------------------------------------------------------
# resource "aws_acm_certificate" "main" {
#   count             = var.environment == "prod" ? 1 : 0  # Only create in prod
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   subject_alternative_names = [
#     "*.${var.domain_name}" # Covers all subdomains
#   ]

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name        = "${var.domain_name}-wildcard-certificate"
#     Environment = "shared"
#     ManagedBy   = "Terraform"
#   }
# }

# # -----------------------------------------------------------------------------
# # Certificate Validation (Production only)
# # -----------------------------------------------------------------------------
# resource "aws_route53_record" "cert_validation" {
#   for_each = var.environment == "prod" ? {
#     for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   } : {}

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = local.zone_id
# }

# resource "aws_acm_certificate_validation" "main" {
#   count                   = var.environment == "prod" ? 1 : 0
#   certificate_arn         = aws_acm_certificate.main[0].arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

# # -----------------------------------------------------------------------------
# # Data source for existing certificate (for non-prod environments)
# # -----------------------------------------------------------------------------
# data "aws_acm_certificate" "existing" {
#   count    = var.environment != "prod" ? 1 : 0
#   domain   = var.domain_name
#   statuses = ["ISSUED"]

#   # If your certificate is in us-east-1 but you're deploying in another region,
#   # you'll need to create a regional certificate
#   most_recent = true
# }

# locals {
#   # Use the created certificate in prod, or the data source in other envs
#   certificate_arn = var.environment == "prod" ? aws_acm_certificate.main[0].arn : data.aws_acm_certificate.existing[0].arn
# }

# # -----------------------------------------------------------------------------
# # ALB (Application Load Balancer)
# # This will be different in each environment
# # -----------------------------------------------------------------------------

# # Uncomment and configure when ready to use
# # resource "aws_lb" "main" {
# #   name               = "${var.environment}-demo-alb"
# #   internal           = false
# #   load_balancer_type = "application"
# #   security_groups    = [aws_security_group.alb.id]
# #   subnets            = [aws_subnet.demo_public_subnet_1.id, aws_subnet.demo_public_subnet_2.id]
# #
# #   enable_deletion_protection = var.environment == "prod" ? true : false
# #   enable_http2               = true
# #
# #   tags = {
# #     Name        = "${var.environment}-demo-alb"
# #     Environment = var.environment
# #     ManagedBy   = "Terraform"
# #   }
# # }

# # # HTTPS Listener (using the shared wildcard certificate)
# # resource "aws_lb_listener" "https" {
# #   load_balancer_arn = aws_lb.main.arn
# #   port              = "443"
# #   protocol          = "HTTPS"
# #   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
# #   certificate_arn   = local.certificate_arn
# #
# #   default_action {
# #     type             = "forward"
# #     target_group_arn = aws_lb_target_group.main.arn
# #   }
# # }

# # # HTTP Listener (redirect to HTTPS)
# # resource "aws_lb_listener" "http" {
# #   load_balancer_arn = aws_lb.main.arn
# #   port              = "80"
# #   protocol          = "HTTP"
# #
# #   default_action {
# #     type = "redirect"
# #
# #     redirect {
# #       port        = "443"
# #       protocol    = "HTTPS"
# #       status_code = "HTTP_301"
# #     }
# #   }
# # }

# # -----------------------------------------------------------------------------
# # DNS Record for ALB (Environment-specific)
# # Each environment gets its own subdomain
# # -----------------------------------------------------------------------------

# # Uncomment when ALB is created
# # resource "aws_route53_record" "alb" {
# #   zone_id = local.zone_id
# #   name    = local.environment_domain
# #   type    = "A"
# #
# #   alias {
# #     name                   = aws_lb.main.dns_name
# #     zone_id                = aws_lb.main.zone_id
# #     evaluate_target_health = true
# #   }
# # }

# # # Optional: www subdomain for production
# # resource "aws_route53_record" "www" {
# #   count   = var.environment == "prod" ? 1 : 0
# #   zone_id = local.zone_id
# #   name    = "www.${var.domain_name}"
# #   type    = "A"
# #
# #   alias {
# #     name                   = aws_lb.main.dns_name
# #     zone_id                = aws_lb.main.zone_id
# #     evaluate_target_health = true
# #   }
# # }

# # -----------------------------------------------------------------------------
# # Outputs
# # -----------------------------------------------------------------------------
# output "route53_zone_id" {
#   description = "Route53 hosted zone ID"
#   value       = local.zone_id
# }

# output "route53_nameservers" {
#   description = "Name servers for the domain (update at registrar if newly created)"
#   value       = var.environment == "prod" ? aws_route53_zone.main[0].name_servers : []
# }

# output "acm_certificate_arn" {
#   description = "ACM Certificate ARN"
#   value       = local.certificate_arn
# }

# output "environment_domain" {
#   description = "Full domain name for this environment"
#   value       = local.environment_domain
# }

# # output "alb_dns_name" {
# #   description = "ALB DNS name"
# #   value       = aws_lb.main.dns_name
# # }

# # output "environment_url" {
# #   description = "Full HTTPS URL for this environment"
# #   value       = "https://${local.environment_domain}"
# # }
