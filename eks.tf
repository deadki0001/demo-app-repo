// Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.
// For a more ind depth read on VPC's, I have included a readme.txt with the AWS Whitepaper which will provide you with any additional context.

# checkov:skip=CKV2_AWS_11:VPC flow logging disabled for demo environment to reduce costs
# checkov:skip=CKV2_AWS_12:Default security group restrictions handled separately
resource "aws_vpc" "demo_application_vpc" {
  cidr_block = "10.0.0.0/16" // = 65, 536 usable addresses within this given network

  tags = {
    Name       = "demo-application-vpc"
    Managed_by = "Terraform"
  }
}

// Restrict the default security group - fixes CKV2_AWS_12
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.demo_application_vpc.id

  # No ingress or egress rules - all traffic blocked
  tags = {
    Name = "demo-vpc-default-sg-restricted"
  }
}

// Optional: Enable VPC Flow Logs (uncomment for production)
// This addresses CKV2_AWS_11 but adds cost, so keeping it commented for demo
# resource "aws_flow_log" "demo_vpc_flow_log" {
#   vpc_id          = aws_vpc.demo_application_vpc.id
#   traffic_type    = "ALL"
#   iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
#   log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
# }

# resource "aws_cloudwatch_log_group" "vpc_flow_log" {
#   name              = "/aws/vpc/demo-application-vpc"
#   retention_in_days = 7
# }

# resource "aws_iam_role" "vpc_flow_log_role" {
#   name = "vpc-flow-log-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "vpc-flow-logs.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy" "vpc_flow_log_policy" {
#   role = aws_iam_role.vpc_flow_log_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "logs:DescribeLogGroups",
#         "logs:DescribeLogStreams"
#       ]
#       Resource = "*"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_nodes.name
# }

# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_nodes.name
# }

# resource "aws_iam_role_policy_attachment" "eks_container_registry" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_nodes.name
# }

# # EKS Node Group
# resource "aws_eks_node_group" "demo" {
#   cluster_name    = aws_eks_cluster.demo.name
#   node_group_name = "demo-node-group"
#   node_role_arn   = aws_iam_role.eks_nodes.arn
#   subnet_ids      = [
#     aws_subnet.demo_private_subnet_1.id,
#     aws_subnet.demo_private_subnet_2.id
#   ]

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }

#   instance_types = ["t3.small"]

#   update_config {
#     max_unavailable = 1
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.eks_worker_node_policy,
#     aws_iam_role_policy_attachment.eks_cni_policy,
#     aws_iam_role_policy_attachment.eks_container_registry,
#   ]

#   tags = {
#     Name = "demo-eks-nodes"
#   }
# }

# # OIDC Provider for IRSA (IAM Roles for Service Accounts)
# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer

#   tags = {
#     Name = "eks-oidc-provider"
#   }
# }

# # Output for kubectl config
# output "eks_cluster_endpoint" {
#   value = aws_eks_cluster.demo.endpoint
# }

# output "eks_cluster_name" {
#   value = aws_eks_cluster.demo.name
# }

# output "configure_kubectl" {
#   value = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.demo.name}"
# }
#
