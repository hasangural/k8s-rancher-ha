# Wipe Docker
echo "[TASK 1] Wipe Docker"
sudo apt-get remove docker docker-engine docker.io containerd runc >/dev/null 2>&1

# Update
echo "[TASK 2] Getting Update"
sudo apt-get -y update >/dev/null 2>&1

# Install packages to allow apt to use repo over https
echo "[TASK 3] Install packages to allow apt to use repo over https"
sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common >/dev/null 2>&1

# Add Docker official GPG Key
echo "[TASK 4] Add Docker official GPG Key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >/dev/null 2>&1

# Setting up 
echo "[TASK 5] Setting up Repository"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/dev/null 2>&1

# Getting Update
echo "[TASK 6] Getting Update"
sudo apt-get -y update >/dev/null 2>&1

# Installing Docker
echo "[TASK 7] Installing Docker"
sudo apt-get -y install docker-ce docker-ce-cli containerd.io >/dev/null 2>&1

# Create Docker Group
echo "[TASK 8] Create Docker Group"
sudo groupadd docker >/dev/null 2>&1

# Add User to the docker Group
echo "[TASK 9] Add User to the docker Group"
sudo usermod -aG docker $USER

# Activate Changes
echo "[TASK 10] Activate Changes"
newgrp docker

# Activate Changes
echo "[TASK 11] Rebooting your server  "
/sbin/shutdown -r now
