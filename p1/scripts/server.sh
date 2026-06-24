#!/bin/bash

# Set up a common Bash (shell) safety configuration:
# -e           The script immediately stops if any command returns a non-zero exit code (an error)
# -u           The script immediately stops if any variable is unset
# -o pipefail  The whole pipeline fails if any command fails. The script returns the exit code of 
#              the last command in a pipeline that failed.
set -euo pipefail
# apt-get update && apt-get install -y curl bash

# Private network IP of the K3s server
SERVER_IP="192.168.56.110"
# Default location of the K3s node token
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"

echo ">>> Installing K3s in server mode..."

# Install K3s server)
# curl -sfL https://get.k3s.io  Download the K3s installation script from the official source.
#   -s                          Silently install K3s.
#   -f                          Fail silently on server errors.
#   -L                          Follow redirects.
#   https://get.k3s.io          Official K3s installation script.
# | sh -s - server [options]    Pipe the installation script to the shell and run it in server mode.
#   Options:
#   --write-kubeconfig-mode 644 Allows vagrant user to read kubeconfig.
#   --bind-address              Bind API server to the private network IP.
#   --advertise-address         The IP agents use to reach the API server.
#   --node-ip                   Node's IP in the cluster, recommendet to specify the value explicitly.
#   --flannel-iface             Specify the network interface (eth1 - private network interface in Vagrant).
curl -sfL https://get.k3s.io | sh -s - server \
    --write-kubeconfig-mode=644 \
#    --bind-address "${SERVER_IP}" \
#    --advertise-address "${SERVER_IP}" \
    --node-ip="${SERVER_IP}" \
    --tls-san="${SERVER_IP}"
#    --flannel-iface eth1

# Wait for K3s to be ready
echo ">>> Waiting for K3s server to be ready..."
# Check if the K3s server is ready by using kubectl to get the nodes and grep for "Ready" status.
# Ignore errors (2>/dev/null) in case kubectl is not yet available or the cluster is not ready.
# If not ready, wait for 5 seconds and check again.
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    echo "  ... still waiting"
    sleep 5
done

# Make kubectl available to vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
# Update server address in kubeconfig to use the private IP
# Before:   https://127.0.0.1:6443
# After:    https://192.168.56.110:6443
# 6443:     Kubernetes API server HTTPS port (standard convention)
sed -i "s/127.0.0.1/${SERVER_IP}/g" /home/vagrant/.kube/config
# Change ownership of the kubeconfig directory to the vagrant user so that kubectl can be used without sudo
chown -R vagrant:vagrant /home/vagrant/.kube

# Share token via shared folder (vagrant syncs /vagrant to host)
echo ">>> Saving node token..."
cat "${TOKEN_FILE}" > /vagrant/node-token

echo ">>> K3s server ready. Node token saved to /vagrant/node-token"
# Show the nodes in the cluster (should show only the server node at this point)
kubectl get nodes -o wide
