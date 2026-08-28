output "deployment_name" {
  value = kubernetes_deployment.app.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.app.metadata[0].name
}

output "ingress_host" {
  value = var.ingress_host
}
