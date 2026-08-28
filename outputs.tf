output "ecr_repository_url" {
  description = "Depot ECR (pour docker tag / push)"
  value       = module.ecs.ecr_repository_url
}

output "ecs_url" {
  description = "URL publique de l'application sur ECS"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster" {
  value = module.ecs.cluster_name
}

output "ecs_service" {
  value = module.ecs.service_name
}
