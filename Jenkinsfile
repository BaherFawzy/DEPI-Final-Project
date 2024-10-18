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

        stage('Create ArgoCD Application') {
            steps {
                script {
                    echo "Creating ArgoCD Application..."

                    sh '''
                        # Set ArgoCD app name and repo details
                        ARGOCD_APP_NAME="to-do-app"
                        ARGOCD_REPO_URL="https://github.com/sharara99/DEPI-Final-Project.git"
                        ARGOCD_PATH="k8s/helm/app"
                        ARGOCD_NAMESPACE="to-do-app"
                        ARGOCD_CLUSTER="https://kubernetes.default.svc"

                        # Read ArgoCD admin password from the file created by the deploy-argocd-minikube.sh script
                        if [ ! -f argo-pass.txt ]; then
                            echo "ArgoCD password file not found!"
                            exit 1
                        fi

                        ARGOCD_PASSWORD=$(cat argo-pass.txt)

                        # Get the ArgoCD server URLs
                        ARGOCD_SERVER_URLS=($(minikube service -n argocd argocd-server --url))

                        # Select one of the URLs (here we simply choose the first one)
                        ARGOCD_SERVER_URL=${ARGOCD_SERVER_URLS[0]}  # or use ${ARGOCD_SERVER_URLS[1]} for the second URL

                        # Login to ArgoCD using the extracted password
                        argocd login --insecure --username admin --password $ARGOCD_PASSWORD --grpc-web $ARGOCD_SERVER_URL

                        # Check if ArgoCD application already exists
                        if argocd app get $ARGOCD_APP_NAME; then
                            echo "Application $ARGOCD_APP_NAME already exists, syncing..."
                            argocd app sync $ARGOCD_APP_NAME
                        else
                            echo "Creating ArgoCD application $ARGOCD_APP_NAME..."
                            argocd app create $ARGOCD_APP_NAME \
                                --repo $ARGOCD_REPO_URL \
                                --path $ARGOCD_PATH \
                                --dest-server $ARGOCD_CLUSTER \
                                --dest-namespace $ARGOCD_NAMESPACE \
                                --sync-policy automated \
                                --auto-prune \
                                --self-heal

                            # Sync the ArgoCD application
                            argocd app sync $ARGOCD_APP_NAME
                        fi
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                script {
                    echo "Deploying application to Kubernetes using Helm..."
                    sh '''
                        # Check if the namespace already exists
                        if kubectl get namespace to-do-app; then
                            echo "Namespace 'to-do-app' already exists, proceeding with deployment..."
                        else
                            echo "Creating namespace 'to-do-app'..."
                            kubectl create namespace to-do-app
                        fi

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
