pipeline {

    agent any

    stages {

        stage('Checkout') {

            steps {
                git branch: 'main',
                    url: 'https://github.com/schandarcse/terraform-project.git'
            }
        }

        stage('Terraform Init') {

            steps {
                bat 'terraform init'
            }
        }

        stage('Terraform Validate') {

            steps {
                bat 'terraform validate'
            }
        }

        stage('Terraform Plan') {

            steps {
                bat 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {

            steps {
                bat 'terraform apply -auto-approve tfplan'
            }
        }
    }
}