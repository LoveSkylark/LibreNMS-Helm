#!/bin/sh

#echo "############## Updatinga Linux ##############"
#export DEBIAN_FRONTEND=noninteractive
#sudo apt update && sudo apt upgrade -y

#echo "############## Installing basic tools ##############"
#apt install vim git

#echo "############## Adding alias for KUBE & HELM##############"
#mv ~/.bash_aliases ~/.bash_aliases.backup
#wget https://raw.githubusercontent.com/LoveSkylark/dotfiles/main/Linux/.bash_aliases ~
#exec "$SHELL"

echo "Downloading and installing K3S"
export INSTALL_K3S_BIN_DIR=/usr/local/bin
curl -sfL 'https://get.k3s.io' | sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Downloading and installing HELM"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "############## Fetching helm chart ##############"
git clone https://github.com/LoveSkylark/LibreNMS-Helm.git
mv ./example.values.yaml.example values.yaml

echo "############## seting up Libre cluster ##############"

echo "usfeull short cuts:"
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
echo "                     2. build the cluster using 'hin <clustername> ./librenms vlaues.yaml (or  <corportation>.yaml)"
echo ""
echo ""
