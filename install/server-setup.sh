#!/bin/sh

echo "############## Updatinga Linux ##############"
echo ""
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
echo ""
echo ""
echo "############## Installing basic tools ##############"
echo ""
apt install vim nano git -y
echo ""
echo ""
echo "############## Downloading and installing K3S ##############"
echo ""
export INSTALL_K3S_BIN_DIR=/usr/local/bin
grep -qxF 'KUBECONFIG="/etc/rancher/k3s/k3s.yaml"' /etc/environment || echo 'KUBECONFIG="/etc/rancher/k3s/k3s.yaml"' >> /etc/environment
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
curl -sfL 'https://get.k3s.io' | sh -
echo ""
echo ""
echo "############## Downloading and installing K9S ##############"
echo ""
curl -sS https://webinstall.dev/k9s | bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo ""
echo ""
echo "############## Downloading and installing HELM ##############"
echo ""
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo ""
echo ""
echo "############## Fetching helm chart ##############"
echo ""
mkdir /data /data/chart
cd /data/chart
git clone https://github.com/LoveSkylark/LibreNMS-Helm.git
cp LibreNMS-Helm/example/values.yaml.example config.yaml
echo ""
echo ""
echo "############## Adding alias for KUBE & HELM##############"
echo ""
mv ~/.bash_aliases ~/.bash_aliases.backup
cp LibreNMS-Helm/install/bash ~/.bash_aliases
echo ""
echo ""
vim -f config.yaml
echo ""
echo "############## Staring up the Cluster ##############"
echo " this may take some time" 
function LibreClusterInstall() 
        {
                helm install librenms /data/chart/LibreNMS-Helm/librenms -f /data/chart/config.yaml
        }

LibreClusterInstall
echo ""
echo ""
echo "          k9s         = manage the kube cluster"
echo ""
echo "          nms-edit    = change cluster configuration"
echo "          nms-help    = libreNMS cli commands"
echo ""
echo "          lnms        = libreNMS cli commands"
echo ""
echo ""
echo ""
echo "  it will take few minutes to build the LibreNMS cluster, you can monitor the proccess by typing 'k9s'"

