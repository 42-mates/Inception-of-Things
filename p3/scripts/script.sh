#!/bin/sh
# ssh-copy-id -p 2222 iot@localhost
# ssh-keygen -t ed25519 -C "abergman@student.42.fr"
# cat ~/.ssh/id_ed25519.pub
#
G='\e[32m'
RE='\e[31m'
Y='\e[33m'
R='\e[0m'

sudo apt update && sudo apt install -y curl vim apache2-utils

echo -e "${G}# install docker${R}"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

echo -e "# install kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

echo -e "# install k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo -e "# create the cluster"
k3d cluster delete k3s-default 2>/dev/null || true
k3d cluster create k3s-default \
  -p 8888:80@loadbalancer

sleep 1

echo -e "# merge and switch context properly"
k3d kubeconfig merge k3s-default --kubeconfig-switch-context

# permissions on kubeconfig
mkdir -p ~/.kube
chmod 600 ~/.kube/config

# kubectl get nodes

# kubectl get nodes
# Disable tls
kubectl config set-cluster k3d-k3s-default --insecure-skip-tls-verify=true

# kubectl get nodes
if [ $? -ne 0 ]; then
    echo -e "${RE}kubectl not connected to cluster${R}"
    exit 1
fi

kubectl delete application wil-playground -n argocd --ignore-not-found=true
kubectl delete appproject wil-playground -n argocd --ignore-not-found=true
kubectl delete namespace dev --ignore-not-found=true --force --grace-period=0

echo "Waiting for namespace dev to be deleted..."
until ! kubectl get namespace dev &>/dev/null; do
    sleep 1
done

sleep 1

echo -e "# create the namespace argocd and dev"
kubectl create namespace argocd 2>/dev/null || true
kubectl create namespace dev 2>/dev/null || true

sleep 1

echo -e "${G}install ArgoCD${R}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# sed -i '/kubectl.kubernetes.io\/last-applied-configuration/d' *.yaml

echo -e "${G}wait preparing of the pods of argocd${R}"
# sudo kubectl get pods -n argocd -w

kubectl wait --for=condition=ready pod --all -n argocd --timeout=10m

if [ $? -eq 0 ]; then
    echo -e "${G}All Argo CD pods are ready!${R}"
else
    exit 1
fi

PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "changing default password to argocd"

HASH=$(htpasswd -nbBC 10 "" admin | tr -d ':\n' | sed 's/\$2y/\$2a/')

echo "Password HASH: $HASH"

kubectl -n argocd patch secret argocd-secret \
  -p "{\"stringData\": {
    \"admin.password\": \"$HASH\",
    \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"
  }}"

kubectl apply -f ../confs/project.yaml -n argocd
kubectl apply -f ../confs/app.yaml -n argocd

# kubectl get pods -n dev
# kubectl get svc -n dev
kubectl get pods -n dev
kubectl describe pod -l app=wil-playground -n dev

until kubectl get svc wil-playground -n dev &>/dev/null; do
    echo "Waiting for Service wil-playground ..."
    sleep 1
done

kubectl get pods -n dev
kubectl describe pod -l app=wil-playground -n dev

sudo kill $(sudo lsof -t -i:8889) 2>/dev/null || true
kubectl port-forward svc/argocd-server -n argocd 8889:443 --address 0.0.0.0 &