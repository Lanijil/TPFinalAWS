variable "app_name" {
  description = "Nom de l'application et du depot ECR (nommage TP1)"
  type        = string
  default     = "web-ipssi"
}

variable "cluster_name" {
  description = "Nom du cluster ECS (nommage TP1/TP2)"
  type        = string
  default     = "ipssi-ecs"
}

variable "service_name" {
  description = "Nom du service ECS (nommage TP1/TP2)"
  type        = string
  default     = "web-svc"
}

variable "region" {
  description = "Region AWS. Academy n'autorise que us-east-1 ou us-west-2 (TP2 §2)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "AWS Academy n'autorise que us-east-1 ou us-west-2."
  }
}

variable "image_tag" {
  description = "Tag de l'image deployee. Jamais 'latest' (TP1 corrige)."
  type        = string
  default     = "1.0.0"

  # Meme regle que la ClusterPolicy Kyverno disallow-latest-tag (TP6 §4.2),
  # appliquee ici a l'admission Terraform plutot qu'a l'admission Kubernetes.
  validation {
    condition     = var.image_tag != "latest" && length(var.image_tag) > 0
    error_message = "Tag 'latest' interdit : utiliser un tag immuable (1.0.0, SHA de commit...)."
  }
}

variable "container_port" {
  description = "Port ecoute par le conteneur (8080 au TP1)"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Chemin de la sonde ALB"
  type        = string
  default     = "/"
}

variable "app_env" {
  description = "Variables d'environnement de l'app (equivalent ConfigMap, TP3 §3.1)"
  type        = map(string)
  default = {
    APP_ENV   = "production"
    APP_TITRE = "IPSSI - Mastere Cyber"
  }
}

variable "desired_count" {
  description = "Nombre de taches souhaite (TP1 : 2 taches)"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 2
    error_message = "Au moins 2 taches pour demontrer la resilience et le rolling update."
  }
}

variable "task_cpu" {
  description = "Unites CPU Fargate"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memoire Fargate en Mio"
  type        = number
  default     = 1024
}

variable "allowed_cidrs" {
  description = "CIDR autorises a joindre l'ALB en HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_autoscaling" {
  description = "Bonus TP2 §5 : Application Auto Scaling. Souvent bloque en Academy (service-linked role)."
  type        = bool
  default     = false
}

variable "max_capacity" {
  description = "Plafond de taches si autoscaling actif"
  type        = number
  default     = 6
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default = {
    Project = "orchestration-ecs-k8s"
    Managed = "terraform"
  }
}
