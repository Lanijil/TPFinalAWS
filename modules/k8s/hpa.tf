resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = var.namespace
  }

  spec {
    min_replicas = var.replica_count
    max_replicas = var.replica_count * 3

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}
