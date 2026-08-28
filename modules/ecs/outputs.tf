output "ecr_repository_url" {
  description = "URL du dépôt ECR (à utiliser pour docker tag/push)"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "URL publique de l'application déployée sur ECS"
  value       = "http://${aws_lb.app.dns_name}"
}

output "cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Nom du service ECS"
  value       = aws_ecs_service.app.name
}
