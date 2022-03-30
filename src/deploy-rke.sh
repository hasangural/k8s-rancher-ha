# Install RKE Binary from Github
echo "[TASK 1] Setting right path for binary"
cd /usr/local/bin

echo "[TASK 2] Downloading the RKE binary from "
wget --output-document=rke https://github.com/rancher/rke/releases/download/v1.1.3/rke_linux-amd64 &> /dev/null

echo "[TASK 3] RKE is now executable by running the following command"
chmod +x rke
rke --version


