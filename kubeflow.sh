###########################
# Kubeflow setup
###########################

# Install local path provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# (To check installation)
kubectl -n local-path-storage get pod
kubectl -n local-path-storage logs -f -l app=local-path-provisioner

# Make this storage class default if not already
kubectl get sc
kubectl patch storageclass <classname> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Download the kfctl v1.2.0 release from the Kubeflow releases page and run this
tar -xvf kfctl_v1.2.0_<platform>.tar.gz


export PATH=$PATH:/home/ubuntu #<path-to-kfctl>
export KF_NAME=my-cluster #<your choice of name for the Kubeflow deployment>
export BASE_DIR=/home/ubuntu/kf-deploy #<path to a base directory>
export KF_DIR=${BASE_DIR}/${KF_NAME}
export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.2-branch/kfdef/kfctl_k8s_istio.v1.2.0.yaml"
mkdir -p ${KF_DIR}
cd ${KF_DIR}

# To build the config change it as per requirement 
kfctl build -V -f ${CONFIG_URI}
export CONFIG_FILE=${KF_DIR}/kfctl_k8s_istio.v1.2.0.yaml
kfctl apply -V -f ${CONFIG_FILE}

# To build using the default config instead
kfctl apply -V -f ${CONFIG_URI}

# check resources
kubectl get all -n kubeflow

#open dashboard at http://localhost:8080 after this command
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80


