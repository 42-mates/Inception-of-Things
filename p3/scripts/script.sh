#!/bin/sh
#
# ssh-keygen -t ed25519 -C "abergman@student.42.fr"
# cat ~/.ssh/id_ed25519.pub
#
G='\e[32m'
R='\e[31m'
Y='\e[33m'
R='\e[0m'
#
# install curl
sudo apt install -y curl vim

echo -e "${G}# install docker${R}"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

echo "# install kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

echo "# install k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "# create the cluster"
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

echo "# create the namespace argocd and dev"
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

sleep 6

echo "${G}install ArgoCD${R}"
# this is config by default
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
