pipeline {
    agent { label 'worker' }

    stages {
        stage('Setup') {
            steps {
                script {
                    git branch: 'main', credentialsId: 'Github', url: 'https://github.com/sharara99/DEPI-Final-Project.git'
                }
            }
        }

        stage('Build Infrastructure') {
            steps {
                script {
                    sh '''
                        cd terraform
                        terraform init
                        terraform plan -out=tfplan

                        # Check if there are changes to be applied
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
                    sh '''
                        ls -la  # Check contents of the Ansible main directory
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
                        sh '''
                            docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
                            ansible-playbook -i /home/vm1/jenkins-slave/workspace/Final-Project/inventory.ini ansible-playbook.yml -e build_number=${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage('Deploy ArgoCD with Helm') {
            steps {
                script {
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

        stage('Add GitHub Repo to ArgoCD') {
            steps {
                script {
                    echo "Adding GitHub repository to ArgoCD..."
                    sh '''
                        # Wait for a moment to ensure ArgoCD is fully up
                        sleep 30

                        # Extract the ArgoCD server URL
                        ARGO_CD_SERVER=$(minikube service -n argocd argocd-server --url)
                        echo "ArgoCD URL: $ARGO_CD_SERVER"
                        
                        # Install ArgoCD CLI if not already installed
                        if ! command -v argocd &> /dev/null; then
                            echo "ArgoCD CLI not found, installing..."
                            curl -sSL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -o argocd
                            chmod +x argocd
                            sudo mv argocd /usr/local/bin/
                        fi
                        
                        # Login to ArgoCD
                        argocd login $ARGO_CD_SERVER --username admin --password $(cat argo-pass.txt)
                        
                        # Add GitHub repository using credentials from Jenkins
                        withCredentials([usernamePassword(credentialsId: 'Github', passwordVariable: 'GITHUB_PASSWORD', usernameVariable: 'GITHUB_USERNAME')]) {
                            argocd repo add https://github.com/sharara99/DEPI-Final-Project.git --username ${GITHUB_USERNAME} --password ${GITHUB_PASSWORD}
                        }
                        
                        # Create ArgoCD application with specified values
                        argocd app create to-do-app \
                            --repo https://github.com/sharara99/DEPI-Final-Project.git \
                            --path k8s/helm \
                            --dest-server https://kubernetes.default.svc \
                            --dest-namespace to-do-app \
                            --project default  # Change if you have a specific project
                        
                        # Optional: Sync the application
                        argocd app sync to-do-app
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                script {
                    echo "Deploying application to Kubernetes using Helm..."
                    sh '''
                        helm upgrade --install helm k8s/helm/app \
                        --namespace to-do-app \
                        --set image.tag=${BUILD_NUMBER} \
                        --create-namespace
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
