#!/bin/sh

cd ~
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
echo ""
echo ""
echo "############## Downloading and installing HELM ##############"
echo ""
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo ""
echo ""
echo "############## Fetching helm chart ##############"
echo ""
git clone https://github.com/LoveSkylark/LibreNMS-Helm.git
cp LibreNMS-Helm/example/values.yaml.example ~/config.yaml
echo ""
echo ""
echo "############## Adding alias for KUBE & HELM##############"
echo ""
mv .bash_aliases .bash_aliases.backup
cp LibreNMS-Helm/install/bash .bash_aliases
echo ""
echo " Press any key to start configuring the cluster"
echo ""
nano ~/config.yaml
echo ""
echo ""
echo "############## Staring up the Cluster ##############"
echo ""
helm install librenms LibreNMS-Helm/librenms -f config.yaml
echo ""
echo ""
echo ""
echo ""
echo ""
echo "############## seting up Libre cluster ##############"
echo ""
echo " usefull short cuts:"
echo "    k=kubectl"
echo "       kl                            // list all resoucess in namsepace"
echo "       kall                          // list all resoucess in all namsepaces"
echo "       kn <namespace>                //switch to another namespace"
echo "       knd <defaul_namespace>        //switch to back to default"
echo "       kbash <pod_name>              // jump into a pod"
echo ""
echo "    h=helm"
echo "       hl                            // list all releases in namsepace"
echo "       hall                          // list all releases in all namsepaces"
echo "       hin                           // helm install"
echo "       hup                           // helm upgrade"
echo "       hun                           // helm uninstall"
echo ""
echo ""
echo "               next step:"
echo "                     1. configure your cluster by editing values.yaml (can be re-named to <corportation>.yaml)" 
echo "                     2. build the cluster using 'hin <clustername> LibreNMS-Helm/librenms config.yaml (or  <corportation>.yaml)"
echo ""
echo ""
exec "$SHELL"
