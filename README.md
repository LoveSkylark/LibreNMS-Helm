# LibreNMS-Helm

This is conversion of librenms/docker + docker-compose to helm + kube, whit alot of new bits an peaces added.



Goal is to build a fully functual monitoring system on fresh install of ubunut.

To install KUBE & HELM simply run:
* wget'https://raw.githubusercontent.com/LoveSkylark/LibreNMS-Helm/main/install/server-setup.sh'
* chmod +x server-setup.sh
* server-setup.sh

 
## Contains:
    * LibreNMS - Application (with weathermap)
    * LibreNMS - Poller
    * LibreNMS - Sylogng
    * LibreNMS - nmptrapd
    * Oxidized - config backup
    * mariadb
    * redis
    * memcached
    * rrdcached
    * msmtpd
  
  
  This is a work in progress.

## TODO:
    * https & cert deploymetn for K3S ingress
    * Weathermap is broken (PHP8 & rrdcahced issues)
    * Oxidized gui no fully intergratin
    * implement Smokeping
    
    
    
    
 
