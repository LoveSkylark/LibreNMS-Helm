<?php

# $config['auth_mechanism'] = 'ldap';
# $config['auth_ldap_server'] = 'ldap.example.com';               // Set server(s), space separated. Prefix with ldaps:// for ssl
# $config['auth_ldap_suffix'] = ',ou=People,dc=example,dc=com';   // appended to usernames
# $config['auth_ldap_groupbase'] = 'ou=groups,dc=example,dc=com'; // all groups must be inside this
# $config['auth_ldap_groups']['admin']['level'] = 10;             // set admin group to admin level
# $config['auth_ldap_groups']['pfy']['level'] = 5;                // set pfy group to global read only level
# $config['auth_ldap_groups']['support']['level'] = 1;            // set support group as a normal user

# $config['radius']['hostname']      = 'localhost';
# $config['radius']['port']          = '1812';
# $config['radius']['secret']        = 'testing123';
# $config['radius']['timeout']       = 3;
# $config['radius']['users_purge']   = 14;  // Purge users who haven't logged in for 14 days.
# $config['radius']['default_level'] = 1;  // Set the default user level when automatically creating a user.

# $config['auth_mechanism'] = 'sso';
# $config['auth_logout_handler'] = '/Shibboleth.sso/Logout';
# $config['sso']['mode'] = 'env';
# $config['sso']['create_users'] = true;
# $config['sso']['update_users'] = true;
# $config['sso']['realname_attr'] = 'displayName';
# $config['sso']['email_attr'] = 'mail';
# $config['sso']['group_strategy'] = 'map';
# $config['sso']['group_attr'] = 'member';
# $config['sso']['group_filter'] = '/(librenms-.*)/i';
# $config['sso']['group_delimiter'] = ';';
# $config['sso']['group_level_map'] = ['librenms-demo' => 11, 'librenms-globaladmin' => 10, 'librenms-globalread' => 5, 'librenms-lowpriv'=> 1];
