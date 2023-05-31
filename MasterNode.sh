#!/bin/bash
#####################################################################################

# Author: Ufuoma EleOvie
# Title: Deploy a 3 Tier Application on Kubernetes Cluster
# Version: 01
# Date: 28-May-2023

# Prerequisites and OS requirements
# To install Docker Engine, you need the 64-bit version of one of these Ubuntu versions:
# Ubuntu Lunar 23.04
# Ubuntu Kinetic 22.10
# Ubuntu Jammy 22.04 (LTS)
# Ubuntu Focal 20.04 (LTS)
# Ubuntu Bionic 18.04 (LTS)
# Docker Engine is compatible with x86_64 (or amd64), armhf, arm64, and s390x architectures.


#####################################################################################




# INSTALL DOCKER (comment off step 1 if Docker was never installed in the server previously)
# If Docker was installed previously and you want to ensure the most up to date version is installed, apply Step 1 to remove all docker packages and dependencies.
Echo “STEP 1: Login as root user and uninstall previous versions and packages
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras -y
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# START THE SCRIPT FROM HERE IF YOU ARE INSTALLING DOCKER IN THE SERVER FOR THE FIRST TIME
echo "Step 2: Install Docker in both the Master & Worker Nodes"
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg

echo "Add Docker’s official GPG key:"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Use the following command to set up the repository:"

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
echo "To install the latest version, run:"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

echo "Step 3: Create a file with the name containerd.conf using the command:"
# create the file with root privileges using the vim editor
sudo vim /etc/modules-load.d/containerd.conf <<EOF
i
overlay
br_netfilter
Esc
:wq
EOF

echo "Step 4: Save the file and run the following commands:"
modprobe overlay
modprobe br_netfilter

echo "Step 5: Create a file with the name kubernetes.conf in /etc/sysctl.d folder:"
# create the file with root privileges using the vim editor
sudo vim /etc/sysctl.d/kubernetes.conf <<EOF
i
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
Esc
:wq
EOF

echo "Step 5: Run the commands to verify the changes:"
sudo sysctl --system
sudo sysctl -p

echo "Step 6: Remove the config.toml file from /etc/containerd/ Folder and run reload your system daemon:"
rm -f /etc/containerd/config.toml
systemctl daemon-reload

echo "Step 7: Add Kubernetes Repository:"
apt-get update && apt-get install -y apt-transport-https ca-certificates curl -y
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Step 8: Disable Swap"
swapoff -a

Step 9: Export the environment variable:
export KUBE_VERSION=1.23.0

echo "Step 10: Install Kubernetes:"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list deb https://apt.kubernetes.io/ kubernetes-xenial main EOF'
sudo apt-cache policy kubelet | head -n 20
wget https://packages.cloud.google.com/apt/dists/kubernetes-xenial/InRelease
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
apt-get install -y kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni=0.8.7-00
sudo apt-mark hold kubelet kubeadm kubectl

echo "Step 11: Now it's time to initialize our Cluster!((Only on master node))"
echo "(Only on master node)"
kubeadm init --kubernetes-version=${KUBE_VERSION}

echo "Step 12:(Only on master node)"
cp /etc/kubernetes/admin.conf /root/
chown $(id -u):$(id -g) /root/admin.conf
export KUBECONFIG=/root/admin.conf
echo 'export KUBECONFIG=/root/admin.conf' >> /root/.bashrc

echo "Step 13: Download the daemonset yaml file of required version like following link:"
wget https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

echo "Step 14: Now apply the daemonset yaml!"
kubectl apply -f weave-daemonset-k8s.yaml

echo “Step 15: Join other nodes to the cluster” 
# Enter this command on the master node only and copy the output  in the intending worker node
kubeadm token create --print-join-command