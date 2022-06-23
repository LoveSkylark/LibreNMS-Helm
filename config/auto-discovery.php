<?php

// v1 or v2c
# $config['snmp']['community'][] = "my_custom_community";
# $config['snmp']['community'][] = "another_community";

// v3
# $config['snmp']['v3'][0]['authlevel'] = 'authPriv';
# $config['snmp']['v3'][0]['authname'] = 'my_username';
# $config['snmp']['v3'][0]['authpass'] = 'my_password';
# $config['snmp']['v3'][0]['authalgo'] = 'SHA';
# $config['snmp']['v3'][0]['cryptopass'] = 'my_crypto';
# $config['snmp']['v3'][0]['cryptoalgo'] = 'AES';

// Discovery methods:
$config['autodiscovery']['bgp'] = false;

// Network ranges
# $config['nets'][] = '192.168.0.0/24';
# $config['nets'][] = '172.2.4.0/22';

// Exlude by network:
# $config['autodiscovery']['nets-exclude'][] = '192.168.0.1/32';

// Exlude by name:
# $config['autodiscovery']['xdp_exclude']['sysname_regexp'][] = '/^dev/';

// Exlude by description:
# $config['autodiscovery']['xdp_exclude']['sysdesc_regexp'][] = '/Vendor X/';

