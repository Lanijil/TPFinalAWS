pipeline {
    agent any
    stages {
        stage("Checkout") {
            steps { checkout scm }
        }
        stage("Init") {
            steps { sh "terraform init -input=false" }
        }
        stage("Validate") {
            steps { sh "terraform fmt -check && terraform validate" }
        }
        stage("Plan") {
            steps { sh "terraform plan -out=tfplan -input=false" }
        }
        stage("Approve") {
            steps { input message: "Appliquer le plan ?" }
        }
        stage("Apply") {
            steps { sh "terraform apply -input=false tfplan" }
        }
    }
    post {
        always { archiveArtifacts artifacts: "tfplan", allowEmptyArchive: true }
    }
}
