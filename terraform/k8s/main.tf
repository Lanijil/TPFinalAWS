terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path    = "/var/lib/jenkins/.kube/config"
  config_context = "minikube"
}

module "k8s" {
  source = "./synchro-jenkins"

  app_name      = "demo-app"
  app_image     = "nginx:1.25"
  replica_count = 2
}
