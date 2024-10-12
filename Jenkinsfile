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
                        sh '''
                            docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
                            ansible-playbook -i /home/vm1/jenkins-slave/workspace/Final-Project/inventory.ini ansible-playbook.yml -e build_number=${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes using Helm..."

                    // Set variables
                    def kubeNamespace = "to-do-app"
                    def dockerImage = "sharara99/to-do-app"
                    def helmReleaseName = "to-do-app"
                    def helmChartPath = "k8s/helm"  // Correct path to your Helm chart

                    // Check if namespace exists
                    def namespaceExists = sh(script: "kubectl get namespaces | grep ${kubeNamespace}", returnStatus: true)

                    if (namespaceExists != 0) {
                        echo "Creating namespace ${kubeNamespace}."
                        sh "kubectl create namespace ${kubeNamespace}"
                    } else {
                        echo "Namespace ${kubeNamespace} already exists."

                        // Check for Helm metadata and add if missing
                        def labelCheck = sh(script: "kubectl get namespace ${kubeNamespace} -o jsonpath='{.metadata.labels.app\\.kubernetes\\.io/managed-by}'", returnStatus: true)
                        if (labelCheck != 0) {
                            echo "Adding Helm labels and annotations to the existing namespace."
                            sh """
                                kubectl label namespace ${kubeNamespace} app.kubernetes.io/managed-by=Helm --overwrite
                                kubectl annotate namespace ${kubeNamespace} meta.helm.sh/release-name=${helmReleaseName} --overwrite
                                kubectl annotate namespace ${kubeNamespace} meta.helm.sh/release-namespace=${kubeNamespace} --overwrite
                            """
                        } else {
                            echo "Namespace ${kubeNamespace} already has the correct Helm metadata."
                        }
                    }

                    // Install or upgrade the Helm release
                    sh """
                        helm upgrade --install ${helmReleaseName} ${helmChartPath} \
                        --namespace ${kubeNamespace} \
                        --set image.repository=${dockerImage} \
                        --set image.tag=${BUILD_NUMBER}
                    """
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
