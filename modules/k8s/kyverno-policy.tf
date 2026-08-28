resource "kubernetes_manifest" "disallow_latest_tag" {
  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-latest-tag"
    }
    spec = {
      validationFailureAction = "Enforce"
      rules = [
        {
          name = "require-image-tag"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            message = "L'utilisation du tag ':latest' est interdite. Merci de spécifier une version précise."
            pattern = {
              spec = {
                containers = [
                  {
                    image = "!*:latest"
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}
