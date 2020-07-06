echo "Please Provide your public name eg: rancher.example.com"
read hostname

echo "Please Provide your email address for public certificate"
read email

echo -en "  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄   '\n'"
echo -en " ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌  '\n'"
echo -en " ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌  '\n'"
echo -en " ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌▐░▌    ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌  '\n'"
echo -en " ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▐░▌   ▐░▌▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌  '\n'"
echo -en " ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌  '\n'"
echo -en " ▐░█▀▀▀▀█░█▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌   ▐░▌ ▐░▌▐░▌          ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀   '\n'"
echo -en " ▐░▌     ▐░▌  ▐░▌       ▐░▌▐░▌    ▐░▌▐░▌▐░▌          ▐░▌       ▐░▌▐░▌          ▐░▌     ▐░▌    '\n'"
echo -en " ▐░▌      ▐░▌ ▐░▌       ▐░▌▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌      ▐░▌   '\n'"
echo -en " ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌  '\n'"
echo -en "  ▀         ▀  ▀         ▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀   '\n'"

#########################################################################################################################################
echo "[TASK 0] Preparing Kubectl and Config File for client"
#Add Google's apt repository gpg key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - >> ~/.bashrc

#Add the Kubernetes apt repository
sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

sudo apt-get update >/dev/null 2>&1
apt-cache policy kubelet | head -n 20  >/dev/null 2>&1
apt-cache policy docker.io | head -n 20  >/dev/null 2>&1
sudo apt-get install -y kubectl >/dev/null 2>&1
cd $home; mkdir .kube; cd k8s-rancher-ha/src/
cp kube_config_cluster.yaml $HOME/.kube/config

apt install -y bash-completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
#########################################################################################################################################

#########################################################################################################################################
# Install Helm for Cluster
echo "[TASK 1] Generating Secret for metallb"
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" >/dev/null 2>&1
#########################################################################################################################################

#########################################################################################################################################
# Install Helm for Cluster
echo "[TASK 2] Installing Helm for your Kubernetes Cluster"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 
chmod 700 get_helm.sh
./get_helm.sh >/dev/null 2>&1
#########################################################################################################################################

#########################################################################################################################################
echo "[TASK 3] Adding NGNIX Ingress Controller to Helm Repo"
# Add Helm Chart and update Repo for NGNIX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1
helm repo update >/dev/null 2>&1
#########################################################################################################################################

#########################################################################################################################################
echo "[TASK 3.1] Installing NGNIX Ingress Controller to your Cluster"
# Install NGNIX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set controller.replicaCount=3 >/dev/null 2>&1
#########################################################################################################################################

#########################################################################################################################################
echo "[TASK 4] Installing Cert Manager to your Cluster"
# Install Cert-Manager Chart
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml --force >/dev/null 2>&1
helm install cert-manager jetstack/cert-manager --version v0.15.0 --namespace cert-manager >/dev/null 2>&1
#########################################################################################################################################

echo "[TASK 4.1] Waiting for pods in 'cert-manager' namespace"
#########################################################################################################################################"
# Waiting for pods in 'cert-manager' namespace
while [[ $(kubectl get pods -n cert-manager -l app=webhook -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]
 do echo "Waiting for pods in 'cert-manager' namespace." && sleep 20 && 
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml --force >/dev/null 2>&1
 done
#########################################################################################################################################

#########################################################################################################################################
echo "[TASK 5] Adding Rancher Binaries to your Repo"
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest >/dev/null 2>&1
helm repo update >/dev/null 2>&1
#########################################################################################################################################

#########################################################################################################################################
echo "[TASK 5.1] Installing Rancher to your Cluster"
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=$hostname --set ingress.tls.source=letsEncrypt --set letsEncrypt.email=$email >/dev/null 2>&1
#########################################################################################################################################
