resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-svc"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = var.app_port
    }

    type = "ClusterIP"
  }
}
