#!/bin/sh

#echo "############## Updatinga Linux ##############"
#export DEBIAN_FRONTEND=noninteractive
#sudo apt update && sudo apt upgrade -y

#echo "############## Installing basic tools ##############"
#apt install vim

#echo "############## Adding alias for KUBE & HELM##############"
#mv ~/.bash_aliases ~/.bash_aliases.backup
#wget https://raw.githubusercontent.com/LoveSkylark/dotfiles/main/Linux/.bash_aliases ~
#exec "$SHELL"

#echo "Downloading and installing K3S"
#export INSTALL_K3S_BIN_DIR=/usr/local/bin
#curl -sfL 'https://get.k3s.io' | sh -

echo "Downloading and installing HELM"
curl -sfL 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' | sh -
