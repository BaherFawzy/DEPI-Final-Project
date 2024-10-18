#!/bin/bash

# Create Namespace
echo "--------------------Create Argocd Namespace--------------------"
kubectl create ns argocd || true

# Deploy Argocd
echo "--------------------Deploy Argocd--------------------"
# Check if ArgoCD components are already up-to-date or need to be applied
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml | grep -q 'unchanged'

if [ $? -eq 0 ]; then
    echo "No changes detected in ArgoCD deployment. Skipping reapply."
else
    echo "Changes detected in ArgoCD deployment. Reapplying..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# Wait 1 minute for the pods to start
echo "--------------------Waiting 1m for the pods to start--------------------"
sleep 1m

# Change ArgoCD Service to NodePort
echo "--------------------Change Argocd Service to NodePort--------------------"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# ArgoCD URL
echo "--------------------ArgoCD URL--------------------"
minikube service -n argocd argocd-server --url

# ArgoCD UI Password
echo "--------------------ArgoCD UI Password--------------------"
echo "Username: admin"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argo-pass.txt
cat argo-pass.txt
