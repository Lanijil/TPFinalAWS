# Ce fichier est un EXEMPLE pour tester votre module K8s en isolation.
# Dans le vrai dépôt du binôme, ce sera fusionné avec le main.tf racine
# qui appelle aussi le module "ecs" (partie de votre collègue).

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

module "k8s" {
  source = "./synchro-jenkins"

  app_name      = "demo-app"
  app_image     = "nginx:1.25"
  replica_count = 2
}