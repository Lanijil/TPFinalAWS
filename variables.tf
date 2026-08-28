variable "region" {
  description = "Region AWS (Academy : us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "image_tag" {
  description = "Tag de l'image applicative, commun aux DEUX cibles"
  type        = string
  default     = "1.0.0"
}

variable "desired_count" {
  description = "Nombre de taches ECS"
  type        = number
  default     = 2
}
