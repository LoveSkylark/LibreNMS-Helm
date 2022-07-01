# LibreNMS-Helm

Translation of librenms/docker docker-compose to helm kube

helm install <name-of-cluster> ./librenms


## Contains:
* LibreNMS - application (with weathermap)
* LibreNMS - poller
* LibreNMS - sylogng
* LibreNMS - snmptrapd

* Oxidized - config backup
  
* mariadb
* redis
* memcached
* rrdcached
* msmtpd
  
  
  This is a work in progress.
  
  K3S ingress config does not contain cerificates setup
