variable "app_name" {
  description = "Nom de l'application (utilisé comme préfixe pour toutes les ressources)"
  type        = string
  default     = "demo-app"
}

variable "app_image" {
  description = "Image du conteneur à déployer (à remplacer par votre image réelle, TAGUÉE)"
  type        = string
  default     = "nginx:1.25"
}

variable "app_port" {
  description = "Port exposé par le conteneur"
  type        = number
  default     = 80
}

variable "replica_count" {
  description = "Nombre de réplicas de base du Deployment"
  type        = number
  default     = 2
}

variable "namespace" {
  description = "Namespace Kubernetes cible"
  type        = string
  default     = "default"
}

variable "ingress_host" {
  description = "Nom d'hôte utilisé pour l'Ingress (ex: demo-app.local)"
  type        = string
  default     = "demo-app.local"
}
