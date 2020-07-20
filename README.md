<p align="center">
    <img alt="MsHowto" src="https://cdn.rancher.com/wp-content/uploads/2016/02/01225954/Rancher-and-Kubernetes.png" width="250" />
  </a>
</p>
<h1 align="center">
  Deploy Kubernetes Cluster on Bare Metal Server with Rancher Kubernetes Engine - Beta v-0.0.1
</h1>

<h3 align="center">
  ⚛️ 📄 🚀
</h3>
<h3 align="center">
  This document will be covering also combination of using MetalLB, Nginx Ingress Controller, Dynamic NFS Storage Provider and Rancher on Bare Metal Server. 
</h3>

- [What’s In This Document](#whats-in-this-document)
- [Preparing Kubernetes Nodes](#preparing-kubernetes-nodes)
  - [Enable SSH passwordless login](#enable-ssh-passwordless-login)
- [Definition file of Kubernetes Cluster.](#definition-file-of-kubernetes-cluster)
  - [Deploying Kubernetes Cluster with RKE](#deploying-kubernetes-cluster-with-rke)
  - [Deploying and Configuring Addons into the Cluster with script](#deploying-and-configuring-addons-into-the-cluster-with-script)
  - [Adding and Removing Kubernetes Nodes with RKE](#adding-and-removing-kubernetes-nodes-with-rke)
  - [Updating Kubernetes Nodes with RKE](#updating-kubernetes-nodes-with-rke)

## What’s In This Document
It will deploy fully configured and ready to use bare metal kubernetes cluster. In the end, you will have public endpoint to access your rancher web interface.
## Preparing Kubernetes Nodes

Function | MySQL / MariaDB | PostgreSQL | SQLite
:------------ | :-------------| :-------------| :-------------
substr | :heavy_check_mark: |   | :heavy_check_mark:

*Name*|*IP*|*OS*|*RAM*|*CPU*|**Role**| 
|----|----|----|----|----|----|
*client-01* |*x.x.x.10* |*Ubuntu 18.04*|*4GB* |*2*| *[ Management Box ]*             |
*node-01*   |*x.x.x.21* |*Ubuntu 18.04*|*16GB*|*4*| *[ controlplane, etcd ]*         |
*node-02*   |*x.x.x.22* |*Ubuntu 18.04*|*16GB*|*4*| *[ controlplane, etcd ]*         |
*node-03*   |*x.x.x.23* |*Ubuntu 18.04*|*16GB*|*4*| *[ worker, etcd ]*               |
*node-04*   |*x.x.x.24* |*Ubuntu 18.04*|*16GB*|*4*| *[ worker ]*                     |
*nfs-srv*   |*x.x.x.30* |*Ubuntu 18.04*|*4GB* |*4*| *[ NFS Storage for Kubernetes ]* |

* Host Names can be defined in the cluster.yaml file so that you don't need to worry about it.
* You can change the IP Adress Space. Static IPs on individual VMs.
* /etc/hosts hosts file includes name to IP mappings for all VMs. Attention that they should match within definition of cluster.yaml file
* Take snapshots prior to installations, this way you can install and revert to snapshot if needed

Due to configuration of LoadBalancer of MetalLB, you need to tell MetalLB to hand out addresses from the x.x.x.50-x.x.x.60 range, using layer 2 mode. Here is the example of configuration of configmap of MetalLB. You will need to remark this range into **cluster.yaml** file.

*Starting IP address*|*Ending IP address*|*Service Type*|
|----|----|----|
*192.168.0.50* |*192.168.0.60* |*Load Balancer*|

| | |
|-|-|
|`NOTE` |  You can follow your own entire range of `IP Addresses`. All of this completely an example.|

---

We start by cloning the k8s-rancher-cluster repository. It contains all the bash scripts and cluster definiation which we needed to set up a cluster.

```bash
# Jump into client-01
ssh root@x.x.x.10

git clone https://github.com/hasangural/k8s-rancher-ha.git

cd k8s-rancher-ha/src

```

### Enable SSH passwordless login

The first step is to generate the SSH keys to enable passwordless SSH access from the administrative / management host to all Kubernetes hosts. SSH into the administrative node (x.x.x.10) as a user who has root permissions. Starting to generate the SSH keys as follows:

```bash 
# you are still in the client-01

ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null

```

Now you can declare your server IP addresses to variable which is called as '**IPS**'

```bash

declare -a IPS=(192.168.0.21 192.168.0.22 192.168.0.23 192.168.0.24)

```

Now we will need to copy the SSH public key from the administrative host to the other nodes, so that we can login without password. This step should be repeated for each Kubernetes node, where the IP address (x.x.x.21, x.x.x.22, x.x.x.23, x.x.x.24) should be replaced with the IP address of all nodes.


```bash

for server in ${IPS[*]}; do
    ssh-copy-id root@$server -o ConnectTimeout=10 -o StrictHostKeyChecking=no
done

# Note: for each server you must need to enter password

```
<details>
  <summary>Click to expand - see example output</summary>

  ```bash
  # You should see the output as below-stated.
  "/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: '/root/.ssh/id_rsa.pub'"
  "/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed"
  "/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys"
  "root@192.168.0.21's password: *********"
  ```
</details>


Once you done copying the ssh public key from the administrative host to the other nodes, now you can take next step which requires for each node. You should function *prep.sh* bash script on all nodes.


```bash

# you should be in directory which is <k8s-rancher-ha/src/>  -- cd k8s-rancher-ha/src/

for server in ${IPS[*]}; do
    echo "Preparing Server > $server"
    cat prep.sh | ssh root@$server
done

```
<details>
  <summary>Click to expand - see example output</summary>

  ```bash
  # You should see the output as below-stated.
  "[TASK 1] Wipe Docker"
  "[TASK 2] Getting Update"
  "[TASK 3] Install packages to allow apt to use repo over https"
  "[TASK 4] Add Docker official GPG Key"
  "[TASK 5] Setting up Repository"
  "[TASK 6] Getting Update"
  "[TASK 7] Installing Docker"
  "[TASK 8] Create Docker Group"
  "[TASK 9] Add User to the docker Group"
  "[TASK 10] Activate Changes"

  ```
</details>

Vanilla ubuntu nodes are ready to become Kubernetes Nodes. We have now to get RKE binaries from GitHub Repository.

```bash
# you should be in directory which is <k8s-rancher-ha/src/>  -- 📁  cd k8s-rancher-ha/src/
bash deploy-rke.sh

```
<details>
  <summary>Click to expand - see output of script</summary>

  ```bash
  # You should see example of output as below-stated.
  "[TASK 1] Setting right path for binary"
  "[TASK 2] Downloading the RKE binary from"
  "[TASK 3] RKE is now executable by running the following command"
  "rke version v1.1.3"
  ```
</details>

## Definition file of Kubernetes Cluster.

When setting up your cluster.yml for RKE, there are a lot of different options that can be configured to control the behavior of how RKE launches Kubernetes.

```
cluster_name: mycluster-rancher        # You can set your own cluster name.

ignore_docker_version: false           # Default container engine is docker.

nodes:
  - address: 192.168.0.21
    user: root                         # username. you must have ssh access to the Server
    role: [controlplane, etcd]         # [controlplane, worker, etcd]
    hostname_override: node-01
    labels:
      type: master
  - address: 192.168.0.22
    user: root                         # username. you must have ssh access to the Server
    hostname_override: node-02
    role: [controlplane, etcd]         # [controlplane, worker, etcd]
    labels:
      type: master
  - address: 192.168.0.23
    user: root                         # username. you must have ssh access to the Server
    hostname_override: node-03
    role: [worker, etcd]               # [controlplane, worker, etcd]
    labels:
      type: worker
  - address: 192.168.0.24
    user: root                         # username. you must have ssh access to the Server
    hostname_override: node-04
    role: [worker ]                    # [controlplane, worker, etcd]
    labels:
      type: worker

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
```

### Deploying Kubernetes Cluster with RKE

RKE uses a cluster configuration file, referred to as cluster.yml to determine what nodes will be in the cluster and how to deploy Kubernetes. There are many configuration options that can be set in the cluster.yml.You will have to manipulate cluster.yaml file regarding your structure. In our file, we will be assuming that configuration will apply your nodes.

```bash
# you should be in directory which is <k8s-rancher/src/>  -- 📁 cd k8s-rancher/src/

rke up --config "../src/cluster.yaml"

```
<details>
  <summary>Click to expand - see example output of RKE </summary>

  ```bash
  # You should see the output as below-stated.
    "INFO[0000] Running RKE version: v1.1.3"
    "INFO[0000] Initiating Kubernetes cluster"
    "INFO[0000] [dialer] Setup tunnel for host [192.168.0.24]"
    "INFO[0000] [dialer] Setup tunnel for host [192.168.0.22]"
    "INFO[0000] [dialer] Setup tunnel for host [192.168.0.21]"
    "INFO[0000] [dialer] Setup tunnel for host [192.168.0.23]"
    "INFO[0001] Checking if container [cluster-state-deployer] is running on host [192.168.0.22], try #1"
    "INFO[0001] Pulling image [rancher/rke-tools:v0.1.58] on host [192.168.0.22], try #1"
    "INFO[0010] Image [rancher/rke-tools:v0.1.58] exists on host [192.168.0.22]"
    "INFO[0016] Starting container [cluster-state-deployer] on host [192.168.0.22], try #1"
    "INFO[0017] [state] Successfully started [cluster-state-deployer] container on host [192.168.0.22]"
    "INFO[0017] Checking if container [cluster-state-deployer] is running on host [192.168.0.23], try #1"
    "INFO[0017] Pulling image [rancher/rke-tools:v0.1.58] on host [192.168.0.23], try #1"

  ```
</details>

### Deploying and Configuring Addons into the Cluster with script

Once the RKE deployment is done, you can deploy the other components via "**install-add-on.sh**" script. It implements ingress rule to your cluster also it configures certificate for your public endpoint.

```bash
# you should be in directory which is <k8s-rancher-ha/src/>  -- cd k8s-rancher-ha/src/

bash install-add-on.sh

```
You should be able to deploy with this script:

✔️ Configuring bash completion. Once you logout from session, you will be eligible for using completion.</br>
✔️ Components of NGINX Ingress Controller </br>
✔️ Components of Cert Manager </br>
✔️ Components of Rancher onto your Kubernetes Cluster </br>
✔️ Components of NFS Client Provisioner <**Optional**>

<details>
  <summary>Click to expand - see example output of install-add-on script </summary>

  ```bash
  # You should see the output as below-stated.
    "[TASK 1] Generating Secret for metallb"
    "[TASK 2] Installing Helm for your Kubernetes Cluster"
    "[TASK 3] Adding NGNIX Ingress Controller to Helm Repo"
    "[TASK 3.1] Installing NGNIX Ingress Controller o your Cluster"
    "[TASK 4] Installing Cert Manager to your Cluster"
    "[TASK 4.1] Waiting for pods in 'cert-manager' namespace"
    "Waiting for pods in 'cert-manager' namespace."
    "Waiting for pods in 'cert-manager' namespace."
    "Waiting for pods in 'cert-manager' namespace."
    "[TASK 5] Adding Rancher Binaries to your Repo"
    "[TASK 5.1] Installing Rancher to your Cluster"
    "[TASK 6] Installing NFS Client Provisioner to your Cluster"
      "Do you want to use NFS Server as Dynamic Provisioner? [Y,n]"
      "Please provide your NFS Server IP Address. eg: 192.168.0.121"
      "Please provide your NFS Server root path.  eg: /exported/path"
      "Would you like to use ReclaimPolicy for within StorageClass for your NFS Server? default: Delete [Delete,Retain]"
      "Would you like to use different Storage ClassName for your NFS Server? default: nfs-server [Y/n]"
         "What will be your storage class name?"
  ```
</details>

### Adding and Removing Kubernetes Nodes with RKE
   **TBC**
### Updating Kubernetes Nodes with RKE
   **TBC**




