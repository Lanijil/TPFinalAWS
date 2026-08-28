terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

# Cible 1 — AWS (identifiants de session Academy, cf. README)
provider "aws" {
  region = var.region
}

# Cible 2 — Kubernetes local (contexte minikube)
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

module "ecs" {
  source = "./modules/ecs"

  region            = var.region
  image_tag         = var.image_tag
  desired_count     = var.desired_count
  health_check_path = "/health"
}

# --- À DÉCOMMENTER quand le module de B est poussé ---------------------------
# module "k8s" {
#   source        = "./modules/k8s"
#   image_tag     = var.image_tag
#   replicas      = 3
# }
