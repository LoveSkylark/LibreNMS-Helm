# LibreNMS-Helm

LibreNMS-Helm is a project that aims to provide a fully functional monitoring system on a fresh installation of Ubuntu using Kubernetes (Kube) and Helm. It is a conversion of the original LibreNMS Docker setup to a Kubernetes-based setup with Helm, incorporating various new features and enhancements.

To install Kube and Helm along with the LibreNMS-Helm setup, follow these steps:

## Run the shell script blow:

   ````bash
   sudo -i
   curl -fsSL https://raw.githubusercontent.com/LoveSkylark/LibreNMS-Installer/main/LibreNMS-Install | sudo bash
   ```
### The script will take some time to install
- Git
- SNMP (client)
- K3S (Kubernetes Server)
- K9S (Kubernetes Management)
- HELM (Kubernetes Deployment)
- LibreNMS (monitoring cluster)

Startup Instructions

## After installation has completed you need to open a new Terminal to the server and run:

   ````bash
   sudo -i
   nms start
   ```

When that is done it will prompt you to configure the cluster

You need to correctly configure:
- storage>path
- application>host>FQDN
- application>host>volumeSize
- mariadb>host>volumeSize
- mariadb>credentials>rootPassword
- mariadb>credentials>user
- mariadb>credentials>password

Other configuration can be adjusted after the initial install

press "a" to start editing the configuration and when your done press "esc" then type ":wq"



## 3. While the cluster is being built you can open another shell and type "k9s" as SUDO to monitor its process

K9S allows you to:
- terminal directly into a pod to run test
- view log files 
- kill pods for reconfiguration or just if they behave badly

Please note that this project is still a work in progress, and improvements and updates are being made.
