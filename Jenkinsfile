pipeline {
    agent any
    stages {
        stage("Checkout") {
            steps { checkout scm }
        }
        stage("Init") {
            steps { dir("terraform") { sh "terraform init -input=false" } }
        }
        stage("Validate") {
            steps { dir("terraform") { sh "terraform fmt -check && terraform validate" } }
        }
        stage("Plan") {
            steps { dir("terraform") { sh "terraform plan -out=tfplan -input=false" } }
        }
        stage("Approve") {
            steps { input message: "Appliquer le plan ?" }
        }
        stage("Apply") {
            steps { dir("terraform") { sh "terraform apply -input=false tfplan" } }
        }
    }
    post {
        always { archiveArtifacts artifacts: "terraform/tfplan", allowEmptyArchive: true }
    }
}
