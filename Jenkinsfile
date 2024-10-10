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
                    echo 'Waiting for 2 minutes...'
                    sh 'sleep 120'  // Sleep for 120 seconds (2 minutes)
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
                    
                    // Apply the Kubernetes namespace, service, and deployment YAML files
                    sh '''
                    kubectl apply -f k8s/namespace.yml
                    kubectl apply -f k8s/service.yml
                    kubectl apply -f k8s/auth-deployment.yml
                    kubectl apply -f k8s/weather-deployment.yml
                    kubectl apply -f k8s/ui-deployment.yml
                    '''

                    // Wait for the deployment to be ready
                    sh "kubectl rollout status deployment/auth-deployment -n weatherapp"
                    sh "kubectl rollout status deployment/weather-deployment -n weatherapp"
                    sh "kubectl rollout status deployment/ui-deployment -n weatherapp"
                    
                    // Update the Kubernetes deployment with the new Docker image (rolling update)
                    sh '''
                    kubectl set image deployment/auth-deployment auth-deployment=sharara99/auth-deployment:${BUILD_NUMBER} --record -n weatherapp
                    kubectl set image deployment/weather-deployment weather-deployment=sharara99/weather-deployment:${BUILD_NUMBER} --record -n weatherapp
                    kubectl set image deployment/ui-deployment ui-deployment=sharara99/ui-deployment:${BUILD_NUMBER} --record -n weatherapp
                    '''
                }
            }
        }
    }
}