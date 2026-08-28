// Pipeline unique : validate -> plan -> approbation -> apply
// Pilote les DEUX cibles (module.ecs + module.k8s) depuis la meme racine
// Terraform : un seul plan, une seule approbation, un seul apply.
// La session AWS Academy doit etre active (cf. README §1) et le contexte
// kubectl "minikube" doit exister (cf. README) pour la cible Kubernetes.

pipeline {
  agent any

  parameters {
    string(
      name: 'IMAGE_TAG',
      defaultValue: '1.0.0',
      description: "Tag de l'image applicative. Jamais 'latest'."
    )
    booleanParam(
      name: 'BUILD_IMAGE',
      defaultValue: false,
      description: "Rebuild + push de l'image vers ECR avant le plan. " +
                   "Necessaire au premier deploiement ou si l'app a change."
    )
    booleanParam(
      name: 'DESTROY',
      defaultValue: false,
      description: 'Detruit toute la stack au lieu de l\'appliquer.'
    )
  }

  environment {
    REGION            = 'us-east-1'
    TF_IN_AUTOMATION  = 'true'
    TF_INPUT          = '0'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 45, unit: 'MINUTES')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    // Le tag 'latest' est refuse ici comme il l'est dans variables.tf et
    // dans build-push.sh : meme regle, appliquee au plus tot.
    stage('Garde-fous') {
      steps {
        sh '''
          set -euo pipefail

          if [ "${IMAGE_TAG}" = "latest" ] || [ -z "${IMAGE_TAG}" ]; then
            echo "Tag 'latest' interdit : utiliser un tag immuable (1.0.0, SHA de commit...)." >&2
            exit 1
          fi

          echo "==> Verification de la session AWS Academy"
          aws sts get-caller-identity \
            || { echo "Session expiree. Rafraichir via AWS Details -> AWS CLI." >&2; exit 1; }
        '''
      }
    }

    stage('Init') {
      steps {
        sh 'terraform init -no-color'
      }
    }

    stage('Validate') {
      steps {
        sh '''
          set -euo pipefail
          terraform fmt -check -recursive -no-color
          terraform validate -no-color
        '''
      }
    }

    // Amorcage : le service ECS ne demarre que si l'image existe deja dans ECR,
    // alors que le depot ECR est lui-meme cree par Terraform (README §2).
    // build-push.sh pousse aussi la meme image dans Minikube (module.k8s
    // reference l'image locale, pas ECR : pas de registre prive pour le
    // cluster local).
    stage('Build & Push') {
      when { expression { params.BUILD_IMAGE && !params.DESTROY } }
      steps {
        sh '''
          set -euo pipefail
          terraform apply -no-color -auto-approve \
            -target=module.ecs.aws_ecr_repository.app \
            -var="image_tag=${IMAGE_TAG}"
          ./scripts/build-push.sh "${IMAGE_TAG}"
        '''
      }
    }

    stage('Plan') {
      steps {
        script {
          def destroyFlag = params.DESTROY ? '-destroy' : ''
          sh """
            set -euo pipefail
            terraform plan -no-color ${destroyFlag} \
              -var="image_tag=${params.IMAGE_TAG}" \
              -out=tfplan
            terraform show -no-color tfplan > plan.txt
          """
        }
        archiveArtifacts artifacts: 'plan.txt', fingerprint: true
      }
    }

    stage('Approbation') {
      steps {
        // Le plan est archive : le relire avant de valider.
        timeout(time: 20, unit: 'MINUTES') {
          input(
            message: params.DESTROY
              ? "DESTRUCTION des DEUX cibles (ECS + Kubernetes). Confirmer ?"
              : "Appliquer le plan ECS + Kubernetes (image ${params.IMAGE_TAG}) ?",
            ok: 'Appliquer'
          )
        }
      }
    }

    stage('Apply') {
      steps {
        sh 'terraform apply -no-color -auto-approve tfplan'
      }
    }

    stage('Verification ECS') {
      when { expression { !params.DESTROY } }
      steps {
        sh '''
          set -euo pipefail

          URL=$(terraform output -raw ecs_url)
          echo "==> Application ECS publiee sur ${URL}"

          # L'ALB met un moment a declarer les cibles saines apres un deploiement.
          for i in $(seq 1 30); do
            CODE=$(curl -s -o /dev/null -w '%{http_code}' "${URL}/health" || true)
            if [ "$CODE" = "200" ]; then
              echo "==> /health OK (ECS)"
              curl -s "${URL}/whoami"
              exit 0
            fi
            echo "    tentative ${i}/30 : /health -> ${CODE}"
            sleep 10
          done

          echo "L'application ECS ne repond pas 200 sur /health apres 5 minutes." >&2
          exit 1
        '''
      }
    }

    stage('Verification Kubernetes') {
      when { expression { !params.DESTROY } }
      steps {
        sh '''
          set -euo pipefail

          NAME=web-ipssi
          echo "==> Attente du rollout Kubernetes (deployment/${NAME})"
          kubectl rollout status "deployment/${NAME}" --timeout=180s

          kubectl get "deployment/${NAME}" "service/${NAME}-svc" \
            "ingress/${NAME}-ingress" "hpa/${NAME}-hpa"
        '''
      }
    }
  }

  post {
    always {
      sh 'rm -f tfplan'
    }
    success {
      echo 'Pipeline terminee avec succes.'
    }
    failure {
      echo 'Echec. Verifier en priorite la validite de la session AWS Academy.'
    }
  }
}
