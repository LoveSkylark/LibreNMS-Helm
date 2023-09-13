# LibreNMS-Helm

LibreNMS-Helm is a project that aims to provide a fully functional monitoring system on a fresh installation of Ubuntu using Kubernetes (Kube) and Helm. It is a conversion of the original LibreNMS Docker setup to a Kubernetes-based setup with Helm, incorporating various new features and enhancements.

To install Kube and Helm along with the LibreNMS-Helm setup, follow these steps:

1. Download the installation script:
   ````bash
   wget 'https://raw.githubusercontent.com/LoveSkylark/LibreNMS-Helm/main/install/server-setup.sh'
   ```

2. Make the script executable:
   ````bash
   chmod +x server-setup.sh
   ```

3. Run the installation script:
   ````bash
   ./server-setup.sh
   ```

The setup includes the following components:

- LibreNMS Application (including Weathermap)
- LibreNMS Poller
- LibreNMS Syslog-ng
- LibreNMS SNMP Trap Daemon (nmptrapd)
- Oxidized (for configuration backup)
- MariaDB (database)
- Redis (caching)
- Memcached (caching)
- Rrdcached (RRD caching)
- msmtpd (SMTP server)

Please note that this project is still a work in progress, and improvements and updates are being made.