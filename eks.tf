# ============================================================================
# Amazon EKS (Elastic Kubernetes Service) Configuration
# ============================================================================
# This file contains all EKS-related resources:
# - EKS Cluster
# - EKS Node Groups
# - IAM Roles and Policies for EKS
# - Security Groups for EKS
# ============================================================================

# Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
# AWS EKS documentation: https://docs.aws.amazon.com/eks/

# -----------------------------------------------------------------------------
# EKS Cluster IAM Role
# -----------------------------------------------------------------------------
# This IAM role allows the EKS service to manage resources on your behalf
# The EKS service needs permission to create load balancers, modify network interfaces, etc.

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.environment}-demo-eks-cluster-role"

  # Trust policy: allows the EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.environment}-eks-cluster-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach the AWS-managed EKS Cluster Policy
# This policy provides the necessary permissions for EKS to manage your cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach VPC Resource Controller policy
# This allows the EKS cluster to manage network interfaces and security groups
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# -----------------------------------------------------------------------------
# EKS Cluster Security Group
# -----------------------------------------------------------------------------
# Additional security group for the EKS cluster control plane
# The EKS service automatically creates a security group, but we create an additional one
# for more fine-grained control if needed

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.demo_application_vpc.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-eks-cluster-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Allow worker nodes to communicate with cluster API server
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  description              = "Allow workstation to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
# The EKS cluster is the control plane for Kubernetes
# It manages the Kubernetes API server, scheduler, and other control plane components
# Worker nodes (managed by node groups) connect to this cluster

resource "aws_eks_cluster" "demo" {
  name     = "${var.environment}-demo-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28" # Kubernetes version - update as needed

  # VPC configuration for the cluster
  vpc_config {
    # Deploy control plane across private subnets for security
    subnet_ids = [
      aws_subnet.demo_private_subnet_1.id,
      aws_subnet.demo_private_subnet_2.id
    ]

    # Allow private access from within VPC
    endpoint_private_access = true

    # Allow public access to the cluster endpoint
    # Set to false in production if you only want VPC-internal access
    endpoint_public_access = true

    # Additional security groups for the cluster
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  # Enable control plane logging for troubleshooting and auditing
  # These logs are sent to CloudWatch Logs
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Wait for IAM role policies to be attached before creating the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]

  tags = {
    Name        = "${var.environment}-demo-eks-cluster"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for EKS Cluster Logs
# -----------------------------------------------------------------------------
# Store EKS control plane logs in CloudWatch for monitoring and troubleshooting

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.environment}-demo-eks-cluster/cluster"
  retention_in_days = 7 # Adjust retention as needed (7, 14, 30, 60, 90, etc.)

  tags = {
    Name        = "${var.environment}-eks-cluster-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# EKS Node Group IAM Role
# -----------------------------------------------------------------------------
# This IAM role is assumed by the EC2 instances that serve as Kubernetes worker nodes
# These nodes run your containerized applications

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.environment}-demo-eks-node-group-role"

  # Trust policy: allows EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.environment}-eks-node-group-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach required AWS-managed policies for EKS worker nodes
# These policies allow the nodes to:
# - Communicate with the EKS cluster
# - Pull container images from ECR
# - Manage network interfaces and IP addresses
resource "aws_iam_role_policy_attachment" "eks_node_group_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # Core EKS worker node permissions
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # Networking (CNI) permissions
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # Pull images from ECR
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_node_group_role.name
}

# Additional policy for CloudWatch logging from nodes
resource "aws_iam_role_policy_attachment" "eks_node_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

# -----------------------------------------------------------------------------
# EKS Node Group Security Group
# -----------------------------------------------------------------------------
# Security group for the worker nodes
# Controls inbound and outbound traffic for the EC2 instances running your pods

resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.demo_application_vpc.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name                                                        = "${var.environment}-eks-nodes-sg"
    Environment                                                 = var.environment
    ManagedBy                                                   = "Terraform"
    "kubernetes.io/cluster/${var.environment}-demo-eks-cluster" = "owned"
  }
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
}

# Allow nodes to receive communication from the cluster control plane
resource "aws_security_group_rule" "nodes_cluster_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# Allow pods to communicate with the cluster API server
resource "aws_security_group_rule" "cluster_api_to_nodes" {
  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# -----------------------------------------------------------------------------
# EKS Node Group
# -----------------------------------------------------------------------------
# Node groups are groups of EC2 instances that run your Kubernetes workloads
# EKS automatically handles:
# - Provisioning EC2 instances
# - Joining them to the cluster
# - Updating them (when you change the configuration)
# - Scaling them (based on your min/max/desired settings)

resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "${var.environment}-demo-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn

  # Deploy worker nodes in private subnets
  # This keeps them off the public internet while allowing outbound connections via NAT
  subnet_ids = [
    aws_subnet.demo_private_subnet_1.id,
    aws_subnet.demo_private_subnet_2.id
  ]

  # Scaling configuration
  # - desired_size: How many nodes to run normally
  # - max_size: Maximum nodes during scale-up events
  # - min_size: Minimum nodes (don't go below this)
  scaling_config {
    desired_size = var.environment == "prod" ? 3 : 2 # More nodes in production
    max_size     = var.environment == "prod" ? 5 : 3
    min_size     = var.environment == "prod" ? 2 : 1
  }

  # Update configuration
  # This determines how nodes are updated when you make changes
  update_config {
    max_unavailable = 1 # Only update one node at a time to maintain availability
  }

  # EC2 instance configuration
  instance_types = ["t3.medium"] # 2 vCPUs, 4 GiB RAM - adjust based on workload
  capacity_type  = "ON_DEMAND"   # Use ON_DEMAND for predictable costs, or SPOT for savings

  # Disk configuration for worker nodes
  disk_size = 20 # GB - size of the EBS volume attached to each node

  # Configure how Kubernetes updates node labels and taints
  # This ensures pods are properly drained before nodes are terminated
  force_update_version = false

  # Labels to apply to all nodes in this node group
  # You can use these labels in pod scheduling (nodeSelector, affinity)
  labels = {
    Environment = var.environment
    NodeGroup   = "demo-node-group"
  }

  # Wait for IAM role policies to propagate before creating nodes
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policies,
    aws_eks_cluster.demo
  ]

  tags = {
    Name        = "${var.environment}-demo-node-group"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Lifecycle configuration
  # Ignore changes to desired_size if you plan to use cluster autoscaler
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# OIDC Provider for EKS
# -----------------------------------------------------------------------------
# OIDC provider allows Kubernetes service accounts to assume IAM roles
# This is required for:
# - AWS Load Balancer Controller
# - External DNS
# - Cluster Autoscaler
# - Any other k8s services that need AWS permissions

data "tls_certificate" "eks" {
  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.environment}-eks-oidc-provider"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
# These outputs can be used by other Terraform configurations
# or to configure kubectl access to the cluster

output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.demo.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.demo.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.demo.arn
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.demo.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.demo.identity[0].oidc[0].issuer, null)
}

output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.demo.id
}

output "eks_node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.demo.status
}

# -----------------------------------------------------------------------------
# Helpful Commands (Comments)
# -----------------------------------------------------------------------------
# After deploying the EKS cluster, configure kubectl access:
#
# aws eks update-kubeconfig --region us-east-2 --name demo-eks-cluster
#
# Verify cluster access:
# kubectl get nodes
# kubectl get pods -A
#
# Deploy an application:
# kubectl create deployment nginx --image=nginx
# kubectl expose deployment nginx --port=80 --type=LoadBalancer
#
# View logs:
# kubectl logs -f deployment/nginx
