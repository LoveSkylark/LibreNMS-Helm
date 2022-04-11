# LibreNMS-Helm

Translation of librenms/docker docker-compose to helm kube

helm install LibreNMS ./LibreChart


## Contains:
* LibreNMS - application (with weathermap)
* LibreNMS - poller
* LibreNMS - sylogng
* LibreNMS - snmptrapd
  
* mariadb
* redis
* memcached
* rrdcached
* msmtpd
  
  
  This is a work in progress, cluster has been spun up but has not been exposed or tested.
  Needs to be move into namespace
