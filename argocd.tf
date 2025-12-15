# # ArgoCD Installation and Configuration
# # This deploys ArgoCD to your EKS cluster using the Helm provider

# # Helm provider configuration
# terraform {
#   required_providers {
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 2.12"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.24"
#     }
#   }
# }

# # Get EKS cluster authentication
# data "aws_eks_cluster" "cluster" {
#   name = aws_eks_cluster.demo.name
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = aws_eks_cluster.demo.name
# }

# # Configure Kubernetes provider
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

# # Configure Helm provider
# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }

# # Create ArgoCD namespace
# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#   }
# }

# # Install ArgoCD using Helm
# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = "5.55.0"
#   namespace  = kubernetes_namespace.argocd.metadata[0].name

#   values = [
#     yamlencode({
#       # Server configuration
#       server = {
#         service = {
#           type = "LoadBalancer" # Expose ArgoCD UI via LoadBalancer
#         }
#         extraArgs = [
#           "--insecure" # For demo - in production use TLS
#         ]
#       }

#       # Configure SSO and RBAC (optional)
#       configs = {
#         params = {
#           "server.insecure" = true
#         }
#         cm = {
#           # Automatically sync applications
#           "timeout.reconciliation" = "180s"
#         }
#       }

#       # Redis for caching
#       redis = {
#         enabled = true
#       }
#     })
#   ]

#   depends_on = [
#     aws_eks_cluster.demo,
#     aws_eks_node_group.demo
#   ]
# }

# # Create ArgoCD Application for your demo app
# resource "kubernetes_manifest" "demo_app_argocd_application" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = "demo-app-${var.environment}"
#       namespace = "argocd"
#     }
#     spec = {
#       project = "default"
      
#       # Source: Your deployment manifests repo
#       source = {
#         repoURL        = "https://github.com/deadki0001/aws-community-labs"
#         targetRevision = var.environment == "prod" ? "main" : var.environment
#         path           = "deployments/${var.environment}"
#       }

#       # Destination: This EKS cluster
#       destination = {
#         server    = "https://kubernetes.default.svc"
#         namespace = "demo-app"
#       }

#       # Sync policy
#       syncPolicy = {
#         automated = {
#           prune    = true  # Delete resources not in git
#           selfHeal = true  # Auto-sync if drift detected
#         }
#         syncOptions = [
#           "CreateNamespace=true"
#         ]
#       }
#     }
#   }

#   depends_on = [helm_release.argocd]
# }

# # Get ArgoCD admin password
# data "kubernetes_secret" "argocd_initial_admin_secret" {
#   metadata {
#     name      = "argocd-initial-admin-secret"
#     namespace = "argocd"
#   }

#   depends_on = [helm_release.argocd]
# }

# # Outputs
# output "argocd_server_url" {
#   value       = "http://${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname}"
#   description = "ArgoCD Server URL"
# }

# output "argocd_admin_password" {
#   value       = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
#   description = "ArgoCD admin password"
#   sensitive   = true
# }

# # Get ArgoCD server service
# data "kubernetes_service" "argocd_server" {
#   metadata {
#     name      = "argocd-server"
#     namespace = "argocd"
#   }

#   depends_on = [helm_release.argocd]
# }