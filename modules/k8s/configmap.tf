resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = var.namespace
  }

  data = {
    APP_ENV  = "production"
    APP_NAME = var.app_name
  }
}
