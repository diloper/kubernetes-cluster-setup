######################################################################################################################################################
# Master Node Setup:
######################################################################################################################################################

# Purge all of kubernetes and docker: (not required if working on fresh instance)
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo kubeadm reset # Also remove config files at $HOME/.kube
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*
sudo rm -rf ~/.kube
sudo apt-get autoremove

# Install basic dependencies
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y  containerd.io=1.2.13-2 docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)

# Remove old folder if present
DIR=/etc/docker
if [ -d "$DIR" ]; then
    printf '%s\n' "Removing Lock ($DIR)"
    sudo rm -rf "$DIR"
fi

# Update docker config
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
 	"max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF

# Start docker service
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

# Download Kubernetes
sudo apt-get update && sudo apt-get install -y apt-transport-https 
curl -s	https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list 
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

# For master node creation (Using flannel plugin)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 # Save 'kubeadm join' command given in output for worker node setup
sudo cp /etc/kubernetes/admin.conf $HOME/ # Set kubectl config
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml # Add networking plugin deamonSet

# Add NVIDIA device plugin
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.7.3/nvidia-device-plugin.yml 
