######################################################################################################################################################
# Worker nodes:
######################################################################################################################################################

# Purge NVIDIA driver and install fresh one (Not required if woking with fresh instance):
sudo apt-get purge nvidia*

# Install NVIDIA drivers (using package manager - recommended)
sudo apt-get install linux-headers-$(uname -r)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-$distribution.pin
sudo mv cuda-$distribution.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/7fa2af80.pub
echo "deb http://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64 /" | sudo tee /etc/apt/sources.list.d/cuda.list
sudo apt-get update
sudo apt-get -y install cuda-drivers

# Install NVIDIA drivers (using run file - not necessary if installed already using package manager)
BASE_URL=https://us.download.nvidia.com/tesla
DRIVER_VERSION=450.80.02
curl -fSsl -O $BASE_URL/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run
sudo chmod 777 NVIDIA-Linux-x86_64-$DRIVER_VERSION.run
sudo service lightdm stop
sudo init 3
sudo ./NVIDIA-Linux-x86_64-$DRIVER_VERSION.run
sudo apt install linux-headers-$(uname -r)

# Purge all of kubernetes and docker: (not required if working on fresh instance)
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo kubeadm reset
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
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list 
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Setup nvidia docker:
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

sudo vi /etc/docker/daemon.json
#Replace all text with following:
{
    "default-runtime": "nvidia",
    "exec-opts": ["native.cgroupdriver=systemd"], "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime", "storage-driver": "overlay2", "runtimeArgs": []
        }
    }
}

sudo systemctl restart docker
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Join with kubeadm (get value of variables from output of 'kubeadm init' command in master node)
sudo kubeadm join --token <token> <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:<hash>
