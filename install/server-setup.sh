#!/bin/bash

# Define variables
BIN_DIR="/usr/local/bin"
K3S_INSTALL_SCRIPT="https://get.k3s.io"
K9S_INSTALL_SCRIPT="https://webi.sh/k9s"
CHART_DIR="/data/chart"
LIBRENMS_CHART="LibreNMS-Helm/librenms/"
CONFIG_FILE="$CHART_DIR/config.yaml"

# Function to install LibreNMS cluster
function LibreClusterInstall() {
    helm install librenms "$CHART_DIR/$LIBRENMS_CHART" -f "$CONFIG_FILE"
}

# Function to add LibreNMS IP to SNMP monitoring
function LibreSNMPadd() {
    ip_eth=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    ip_ens=$(/sbin/ip -o -4 addr list ens160 | awk '{print $4}' | cut -d/ -f1)

    if [ "$ip_ens" ]; then
        echo "Adding $ip_ens to SNMP monitoring..."
        kubectl exec --namespace=librenms --stdin --tty lnms-dispatcher-0 -- /usr/bin/lnms device:add -2 -c locallibremon -r 1161 -d LibreNMS "$ip_ens"
    elif [ "$ip_eth" ]; then
        echo "Adding $ip_eth to SNMP monitoring..."
        kubectl exec --namespace=librenms --stdin --tty lnms-dispatcher-0 -- /usr/bin/lnms device:add -2 -c locallibremon -r 1161 -d LibreNMS "$ip_eth"
    else
        echo "No IP address could be found for SNMP monitoring."
    fi
}

# Start of the script

echo "################## Updating Linux ##################"
sudo apt update && sudo apt upgrade -y


echo ""
echo "################## Installing essential tools ##################"
sudo apt install -y curl git vim


echo "################## Adding aliases  ##################"
echo "This step sets up convenient aliases for managing Kubernetes and Helm."
echo ""
sudo cp "$CHART_DIR/LibreNMS-Helm/install/aliases.sh" /etc/profile.d/aliases.sh
echo ""


echo ""
echo "################## Downloading and installing K3S ##################"
echo "This step installs K3s, a lightweight Kubernetes distribution."
echo ""
grep -qxF 'KUBECONFIG="/etc/rancher/k3s/k3s.yaml"' /etc/environment || echo 'KUBECONFIG="/etc/rancher/k3s/k3s.yaml"' >> /etc/environment
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export INSTALL_K3S_BIN_DIR="$BIN_DIR"
curl -sfL "$K3S_INSTALL_SCRIPT" | sudo sh -
echo ""


echo "################## Downloading and installing K9S ##################"
echo "This step installs K9s, a terminal-based Kubernetes dashboard."
echo ""
curl -sS "$K9S_INSTALL_SCRIPT" | sudo sh -

# Move k9s binary to the BIN_DIR if it exists
if [ "$(id -u)" -eq 0 ]; then
    if [ -f "/root/.local/bin/k9s" ]; then
        sudo mv "/root/.local/bin/k9s" "$BIN_DIR/"
    fi
else
    if [ -f "/home/$USER/.local/bin/k9s" ]; then
        sudo mv "/home/$USER/.local/bin/k9s" "$BIN_DIR/"
    fi
fi
echo ""


echo "################## Downloading and installing Helm ##################"
echo "This step installs Helm, the Kubernetes package manager."
echo ""
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo ""


echo "################## Fetching Helm chart for LibreNMS ##################"
echo "This step fetches the LibreNMS Helm chart from the repository."
echo ""
mkdir -p "$CHART_DIR"
cd "$CHART_DIR"
git clone https://github.com/LoveSkylark/LibreNMS-Helm.git
cp "$CHART_DIR/LibreNMS-Helm/example/values.yaml.example" "$CONFIG_FILE"
echo ""

echo "################## Setting up SNMP for LibreNMS ##################"
echo "This step configures SNMP for LibreNMS monitoring."
echo ""
sudo cp "$CHART_DIR/LibreNMS-Helm/install/snmp.conf" /etc/snmp/snmpd.conf.d
sudo systemctl restart snmpd
echo ""


echo "################## Configuring LibreNMS cluster ##################"
echo "This step allows you to configure your LibreNMS cluster."
echo "Please make any necessary changes in the configuration file: $CONFIG_FILE"
echo ""
vim -f "$CONFIG_FILE"
echo ""


echo "################## Starting up the LibreNMS Cluster ##################"
echo "It will take a few minutes to build the LibreNMS cluster."
echo "You can monitor the process by typing 'k9s' in another shell."
echo ""
# Install LibreNMS cluster
LibreClusterInstall
echo ""

echo "################## Adding host to LibreNMS monitoring ##################"
echo "The host is being added to LibreNMS monitoring."
echo ""
# Add LibreNMS IP to SNMP monitoring
LibreSNMPadd
echo ""

echo "################## Installation complete ##################"
echo ""
echo ""
echo "To manage the Kubernetes cluster, use 'k9s' command."
echo "To edit Cluster configuration, use 'nms' command."
echo "For LibreNMS CLI commands, use 'lnms' command."
echo ""
echo ""
echo ""
/bin/bash
