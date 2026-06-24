#!/bin/sh
#
# ssh-keygen -t ed25519 -C "abergman@student.42.fr"
# cat ~/.ssh/id_ed25519.pub
#
G='\e[32m'
RE='\e[31m'
Y='\e[33m'
R='\e[0m'
#
# install curl
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
  --servers 1 \
  --agents 2 \
  --api-port 6443 \
  -p 8088:80@loadbalancer \
  -p 8443:443@loadbalancer

sleep 6

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

sleep 6

echo -e "# create the namespace argocd and dev"
kubectl create namespace argocd 2>/dev/null || true
kubectl create namespace dev 2>/dev/null || true


sleep 6

echo -e "${G}install ArgoCD${R}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# sed -i '/kubectl.kubernetes.io\/last-applied-configuration/d' *.yaml

# sleep 10
echo -e "${G}wait preparing of the pods of argocd${R}"
# sudo kubectl get pods -n argocd -w

kubectl wait --for=condition=ready pod --all -n argocd --timeout=10m

if [ $? -eq 0 ]; then
    echo -e "${G}All Argo CD pods are ready!${R}"
else
    echo -e "${RE}Timeout${R}"
    exit 1
fi

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout argocd.key \
  -out argocd.crt \
  -subj "/CN=argocd-server"

kubectl create secret tls argocd-server-tls \
  --cert=argocd.crt \
  --key=argocd.key \
  -n argocd

kubectl get secret argocd-server-tls -n argocd -o jsonpath='{.data.tls\.crt}' | base64 -d > argocd.crt

# Remove the problem with CRD annotation
# sudo kubectl apply -f install.yaml --server-side --force-conflicts


PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${G}Username: admin, Password: ${PASSWORD} ${R}"

echo "changing default password to argocd"

HASH=$(htpasswd -nbBC 10 "" argocd | tr -d ':\n' | sed 's/\$2y/\$2a/')

echo "Password HASH: $HASH"

kubectl -n argocd patch secret argocd-secret \
  -p "{\"stringData\": {
    \"admin.password\": \"$HASH\",
    \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"
  }}"

echo -e "${Y}start port-forward on 8088${R}"
sudo kill $(sudo lsof -t -i:8088) 2>/dev/null || true
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 &
echo "Username: admin, pass: argocd"
