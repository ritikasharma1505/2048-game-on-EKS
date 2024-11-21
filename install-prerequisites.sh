#!/bin/bash

# Update your system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt install -y unzip curl

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
echo "AWS CLI version:"
aws --version

# Install kubectl
echo "Installing kubectl..."
KUBECTL_VERSION="v1.25.4"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo "kubectl version:"
kubectl version --short

# Install eksctl
echo "Installing eksctl..."
EKSCTL_VERSION="v0.194.0"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" -o eksctl.tar.gz

# Uncomment the following line if you need to remove an old version of eksctl
# sudo rm -f /usr/local/bin/eksctl

tar -xzvf eksctl.tar.gz
sudo mv eksctl /usr/local/bin/
echo "eksctl version:"
eksctl version
