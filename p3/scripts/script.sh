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
sudo apt install -y curl vim

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
sudo k3d cluster delete k3s-default
sudo k3d cluster create k3s-default \
  --servers 1 \
  --agents 2 \
  --api-port 6443 \
  -p 8088:80@loadbalancer \
  -p 8443:443@loadbalancer

sleep 6

sudo k3d kubeconfig merge k3s-default --kubeconfig-switch-context
# kubectl get nodes

sleep 6

echo -e "# create the namespace argocd and dev"
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

sleep 6

echo -e "${G}install ArgoCD${R}"
# this is config by default
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# sed -i '/kubectl.kubernetes.io\/last-applied-configuration/d' *.yaml

sleep 10
echo -e "${G}wait preparing of the pods of argocd${R}"
# sudo kubectl get pods -n argocd -w

sudo kubectl wait --for=condition=ready pod --all -n argocd --timeout=10m

if [ $? -eq 0 ]; then
    echo -e "${G}All Argo CD pods are ready!${R}"
else
    echo -e "${RE}Timeout: Some pods are not ready${R}"
    exit 1
fi

# Remove the problem with CRD annotation
sudo kubectl apply -f install.yaml --server-side --force-conflicts

# Disable tls
sudo kubectl config set-cluster $(kubectl config current-context) --insecure-skip-tls-verify=true 2>/dev/null || true

PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)


echo -e "${G}Username: admin, Password: ${PASSWORD} ${R}"


echo "changing default password to argocd"
sudo kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "abergman.password",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
echo "changed default password to argocd, waiting..."
sleep 3

