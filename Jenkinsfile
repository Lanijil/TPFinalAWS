pipeline {
    agent any
    environment {
        TF_DIR = "terraform/k8s/synchro-jenkins"
    }
    stages {
        stage("Checkout") {
            steps { checkout scm }
        }
        stage("Init") {
            steps { dir("${TF_DIR}") { sh "terraform init -input=false" } }
        }
        stage("Validate") {
            steps { dir("${TF_DIR}") { sh "terraform fmt -check && terraform validate" } }
        }
        stage("Plan") {
            steps { dir("${TF_DIR}") { sh "terraform plan -out=tfplan -input=false" } }
        }
        stage("Approve") {
            steps { input message: "Appliquer le plan ?" }
        }
        stage("Apply") {
            steps { dir("${TF_DIR}") { sh "terraform apply -input=false tfplan" } }
        }
    }
    post {
        always { archiveArtifacts artifacts: "terraform/k8s/synchro-jenkins/tfplan", allowEmptyArchive: true }
    }
}
