# # EKS Cluster - Simple Public Setup for Demo
# # Security features: KMS encryption, audit logs, restricted RBAC

# # KMS key for EKS secrets encryption
# resource "aws_kms_key" "eks" {
#   description             = "EKS Secrets Encryption"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true
# }

# # EKS Cluster IAM Role
# resource "aws_iam_role" "eks_cluster" {
#   name = "demo-eks-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_cluster.name
# }

# # EKS Cluster
# resource "aws_eks_cluster" "demo" {
#   name     = "demo-eks-cluster"
#   role_arn = aws_iam_role.eks_cluster.arn
#   version  = "1.28"

#   vpc_config {
#     subnet_ids              = [
#       aws_subnet.demo_public_subnet_1.id,
#       aws_subnet.demo_private_subnet_1.id,
#       aws_subnet.demo_private_subnet_2.id
#     ]
#     endpoint_public_access  = true  # Public for demo
#     endpoint_private_access = true
#     public_access_cidrs     = ["0.0.0.0/0"]  # Lock this down to your IP in production
#   }

#   encryption_config {
#     provider {
#       key_arn = aws_kms_key.eks.arn
#     }
#     resources = ["secrets"]
#   }

#   enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

#   depends_on = [
#     aws_iam_role_policy_attachment.eks_cluster_policy
#   ]

#   tags = {
#     Name = "demo-eks-cluster"
#   }
# }

# # Node IAM Role
# resource "aws_iam_role" "eks_nodes" {
#   name = "demo-eks-node-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
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