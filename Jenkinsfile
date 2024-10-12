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

                    // Install or upgrade the Helm release
                    sh '''
                        helm install helm k8s/helm --namespace to-do-app --create-namespace
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
