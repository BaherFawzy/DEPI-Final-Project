pipeline {
    agent { label 'worker' }

    stages {
        stage('Setup') {
            steps {
                script {
                    // Checkout the main branch from the GitHub repository
                    git branch: 'main', credentialsId: 'Github', url: 'https://github.com/sharara99/DEPI-Final-Project.git'
                }
            }
        }

        stage('Build Infrastructure') {
            steps {
                script {
                    // Initialize and apply Terraform configurations
                    sh '''
                        cd terraform
                        terraform init
                        terraform plan -out=tfplan

                        # Check for changes before applying
                        if terraform show -json tfplan | jq .resource_changes | grep -q '"change"'; then
                            echo "Changes detected, applying infrastructure changes..."
                            terraform apply -auto-approve tfplan
                        else
                            echo "No changes to infrastructure, skipping apply."
                        fi
                    '''
                }
            }
        }

        stage('Ansible for Configuration and Management') {
            steps {
                script {
                    // Run Ansible playbook for configuration management
                    sh '''
                        ls -la  # List files in the Ansible directory for verification
                        ansible --version
                        ansible-playbook -i inventory.ini ansible-playbook.yml -e build_number=${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Login to Docker Hub and build/push the Docker image
                    withCredentials([usernamePassword(credentialsId: 'DockerHub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}

                        '''
                    }
                }
            }
        }

        stage('Deploy ArgoCD with Helm') {
            steps {
                script {
                    // Deploy ArgoCD using Helm
                    echo "Deploying ArgoCD using Helm..."
                    sh '''
                        ls -la
                        if [ -d "k8s/helm/ArgoCD" ]; then
                            cd k8s/helm/ArgoCD
                            ./deploy-argocd-minikube.sh
                        else
                            echo "Directory k8s/helm/ArgoCD does not exist!"
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Create ArgoCD Application') {
            steps {
                script {
                    // Update the ArgoCD application configuration with the build number
                    echo "Creating ArgoCD Application..."
                    sh '''
                        # Update values.yaml with the build number
                        sed -i "s/tag: \\"latest\\"/tag: \\"${BUILD_NUMBER}\\"/" k8s/helm/app/values.yaml

                    '''

                    sh '''
                        # Apply the ArgoCD application configuration
                        cd k8s/helm/ArgoCD
                        kubectl apply -f argocd-app.yaml
                        
                        # Perform a rolling update for the specific deployment
                        kubectl rollout restart deployment to-do-app-deployment -n to-do-app

                        # Update the Kubernetes deployment with the new Docker image (rolling update)
                        kubectl set image deployment/to-do-app-deployment to-do-app-container=sharara99/to-do-app:${BUILD_NUMBER} --record -n to-do-app
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}
