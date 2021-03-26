######################################################################################################################################################
# Miscellaneous commands
######################################################################################################################################################

# Create new token on master node to join worker nodes
sudo kubeadm token create --print-join-command

# Get pod logs
kubectl logs <pod_name> <container_name>

# run pods on master node as well
kubectl taint nodes --all node-role.kubernetes.io/master-

# Get into shell of running container
kubectl exec --stdin --tty <pod_name> -- /bin/bash # when single containers in pod
kubectl exec -i -t <pod_name> -c <container_name> -- /bin/bash # when multiple containers in pod
#(-i is for --stdin, -t is for --tty, -c is for --container flag respectively)

# To check if GPU of worker node is accessible from master node
telnet <worker_node_hostname/public_ip> 10250 #Ensure port 10250 of worker node is open for master node
kubectl run cuda --image=ubuntu:16.04 --env="LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/local/nvidia/bin" --limits="nvidia.com/gpu=1" --rm -it -- bash 
nvidia-smi

# To smoke test the cluster, run this yaml file
##################################################
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
    - name: cuda-vector-add
      image: "k8s.gcr.io/cuda-vector-add:v0.1"
      resources:
        limits:
          nvidia.com/gpu: 1 # requesting 1 GPU
###################################################
