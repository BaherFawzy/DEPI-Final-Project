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
                }
            }
        }

        stage('Ansible for Configuration and Management') {
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
                        // Pass Docker credentials as environment variables to the Ansible playbook
                        sh '''
                            export DOCKER_USERNAME=${DOCKER_USERNAME}
                            export DOCKER_PASSWORD=${DOCKER_PASSWORD}
                            ansible-playbook -i /home/vm1/jenkins-slave/workspace/Final-Project/inventory.ini ansible-playbook.yml -e build_number=${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes..."

                    // Apply the Kubernetes YAML files
                    sh '''
                        kubectl apply -f k8s/namespace.yml
                        kubectl apply -f k8s/service.yml
                        kubectl apply -f k8s/deployments.yml
                        kubectl apply -f k8s/pvc.yml
                    '''

                    // Wait for the deployments to be fully rolled out with progress checks
                    sh "kubectl rollout status deployment/db -n weather-app --timeout=120s"
                    sh "kubectl rollout status deployment/auth -n weather-app --timeout=120s"
                    sh "kubectl rollout status deployment/weather -n weather-app --timeout=120s"
                    sh "kubectl rollout status deployment/ui -n weather-app --timeout=120s"
                    
                    // Update the Kubernetes deployment with the new Docker image (rolling update)
                    sh '''
                        kubectl set image deployment/auth auth=sharara99/auth:${BUILD_NUMBER} --record -n weather-app
                        kubectl set image deployment/db db=sharara99/db:${BUILD_NUMBER} --record -n weather-app
                        kubectl set image deployment/weather weather=sharara99/weather:${BUILD_NUMBER} --record -n weather-app
                        kubectl set image deployment/ui ui=sharara99/ui:${BUILD_NUMBER} --record -n weather-app
                    '''

                    // Check rollout status after updating images
                    sh "kubectl rollout status deployment/db -n weather-app --timeout=120s"
                    sh "kubectl rollout status deployment/auth -n weather-app --timeout=120s"
                    sh "kubectl rollout status deployment/weather -n weather-app --timeout=120s"
                    sh "kubectl rollout status deployment/ui -n weather-app --timeout=120s"
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            // Add any necessary cleanup steps here, if needed (e.g., removing test deployments)
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}
