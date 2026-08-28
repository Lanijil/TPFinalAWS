variable "app_name" {
  description = "Nom logique de l'application (préfixe de toutes les ressources)"
  type        = string
  default     = "demoapp"
}

variable "region" {
  description = "Région AWS (imposée par Academy)"
  type        = string
  default     = "us-east-1"
}

variable "image_tag" {
  description = "Tag de l'image à déployer. Jamais 'latest'."
  type        = string

  # Garde-fou côté ECS, pendant de la policy Kyverno côté Kubernetes.
  # À citer dans le rapport : le refus du tag mouvant est appliqué
  # symétriquement sur les deux plateformes.
  validation {
    condition     = var.image_tag != "latest" && length(var.image_tag) > 0
    error_message = "Le tag 'latest' est interdit : utiliser un tag immuable (v1.0.0, SHA de commit...)."
  }
}

variable "container_port" {
  description = "Port exposé par le conteneur"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Chemin de la sonde de santé HTTP"
  type        = string
  default     = "/"
}

variable "desired_count" {
  description = "Nombre de tâches souhaité (mise à l'échelle + résilience)"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 2
    error_message = "Au moins 2 tâches sont requises pour démontrer la résilience."
  }
}

variable "task_cpu" {
  description = "Unités CPU Fargate (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Mémoire Fargate en Mio"
  type        = number
  default     = 512
}

variable "allowed_cidrs" {
  description = "CIDR autorisés à joindre l'ALB en HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags communs à toutes les ressources"
  type        = map(string)
  default = {
    Project = "orchestration-ecs-k8s"
    Managed = "terraform"
  }
}
