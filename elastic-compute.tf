# // VPC Module reterived from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
# // For a complete list of configuration items you are welcome to visit the above link.




# // Now that we have created a security group to protect our EC2 from Bad Actors
# // We can create the EC2 Resource. 
# // Utilizing a role to securely give the instance access to login into ECR & Manage Secrets with AWS Secrets Manager.

# // EC2 Instance with security hardening

# resource "aws_iam_role" "demo_app_role" {
#   name = "demo-app-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# # checkov:skip=CKV_AWS_355:Demo environment requires ECR and Secrets Manager access
# # checkov:skip=CKV_AWS_288:Limited scope policy for demo application
# resource "aws_iam_role_policy" "demo_app_policy" {
#   name = "demo-app-policy"
#   role = aws_iam_role.demo_app_role.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "rds:DescribeDBInstances",
#           "secretsmanager:GetSecretValue",
#           "sts:GetCallerIdentity"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_instance_profile" "demo_app_instance_profile" {
#   name = "demo-app-instance-profile"
#   role = aws_iam_role.demo_app_role.name
# }

# # checkov:skip=CKV_AWS_88:Demo environment requires public IP for testing access
# # checkov:skip=CKV_AWS_79:IMDSv2 will be enforced in production, demo uses v1 for compatibility
# # checkov:skip=CKV_AWS_135:t2.micro does not support EBS optimization
# # checkov:skip=CKV_AWS_8:Demo environment, encryption adds complexity without benefit for non-sensitive test data
# # checkov:skip=CKV_AWS_126:Detailed monitoring not required for demo, adds cost
# resource "aws_instance" "demo_app_server" {
#   ami                         = "ami-04b4f1a9cf54c11d0"
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.demo_public_subnet_1.id
#   vpc_security_group_ids      = [aws_security_group.application_security_group.id]
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.demo_app_instance_profile.name

#   # Enable IMDSv2 for better security (fixes CKV_AWS_79)
#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required" # Enforces IMDSv2
#     http_put_response_hop_limit = 1
#   }

#   # Enable detailed monitoring (fixes CKV_AWS_126)
#   monitoring = true

#   user_data = templatefile("${path.module}/user_data.sh", {
#     DB_HOST = aws_db_instance.mysql.address
#     DB_NAME = aws_db_instance.mysql.db_name
#     DB_USER = "admin"
#   })

#   tags = {
#     Name = "demo_app_server"
#   }
# }