pipeline {
    agent { label 'worker' }
    stages {
        stage('Setup') {
            steps {
                git branch: 'main', credentialsId: 'Github', url: 'https://github.com/sharara99/DEPI-Final-Project.git'
            }
        }
        
        stage('Build Infrastructure') {
           steps {
             script {
              sh '''
                cd terraform
                ls -la  # Check contents of the terraform directory
                terraform init
                terraform apply -auto-approve
                '''
                echo 'Waiting for 3 minutes...'
               sh 'sleep 180'  // Sleep for 180 seconds (3 minutes)
        }
    }
}
        
        stage('Ansible for Configuration and Managment') {
            steps {
                script {
                    sh '''
                     ls -la  # Check contents of the ansible main directory
                     ansible --version
                     ansible-playbook -i inventory.ini ansible-playbook.yml
                     '''
                }
            }
        }        

        stage('Build and Push Docker Image') {
          steps {
            script {
            withCredentials([usernamePassword(credentialsId: 'DockerHub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                sh "ansible-playbook -i /home/vm1/jenkins-slave/workspace/Final-Project/inventory.ini ansible-playbook.yml -e build_number=${BUILD_NUMBER}"
            }
          }
         }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Deploying on Kubernetes..."
                    sh "kubectl apply -f flask-pod.yml"
                }
            }
        }
    }
}
