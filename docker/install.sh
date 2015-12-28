#!/bin/bash

cfg=/etc/raddb

# Clients
if [ -e $cfg/clients.conf ]; then
  [ -f $cfg/clients.conf.ori ] || cp $cfg/clients.conf $cfg/clients.conf.ori
  cp /opt/freeradius/samples/clients.sample $cfg/clients.conf
  sed -i -e "s/testing123/$CLIENT_PWD/" $cfg/clients.conf
fi

# Server config
if [ -e $cfg/radiusd.conf ]; then
  sed -i -e "s/max_request_time.*/max_request_time = 120/" $cfg/radiusd.conf
fi

if [ ! -e $cfg/sites-enabled/mobileid ]; then
  rm $cfg/sites-enabled/*
  cp /opt/freeradius/samples/sites-available/mobileid-server $cfg/sites-available/mobileid
  ln -s $cfg/sites-available/mobileid $cfg/sites-enabled/mobileid
fi

# Dictionary
[ -f $cfg/dictionary.ori ] || cp $cfg/dictionary $cfg/dictionary.ori
cp /opt/freeradius/samples/dictionary.sample $cfg/dictionary

# LDAP
[ -f $cfg/mods-available/ldap.ori ] || cp $cfg/mods-available/ldap $cfg/mods-available/ldap.ori
## ln -s $cfg/mods-available/ldap $cfg/mods-enabled/ldap
## TODO: Touch the ldap config

# Files
[ -f $cfg/mods-config/files/authorize.ori ] || cp $cfg/mods-config/files/authorize $cfg/mods-config/files/authorize.ori
cp /opt/freeradius/samples/users.sample $cfg/mods-config/files/authorize

# Mobile ID
cp /opt/freeradius/samples/modules/* $cfg/mods-available/
ln -s $cfg/mods-available/exec_mobileid $cfg/mods-enabled/exec_mobileid
ln -s $cfg/mods-available/exec_ldapupdate $cfg/mods-enabled/exec_ldapupdate

[ -d $cfg/mods-config/mobileid ] || mkdir $cfg/mods-config/mobileid
if [ ! -e /opt/freeradius/exec-mobileid.properties ]; then
  cp /opt/freeradius/exec-mobileid.properties.sample /opt/freeradius/exec-mobileid.properties
  ln -s /opt/freeradius/exec-mobileid.properties $cfg/mods-config/mobileid/exec-mobileid.properties
fi
if [ ! -e /opt/freeradius/exec-ldapupdate.properties ]; then
  cp /opt/freeradius/exec-ldapupdate.properties.sample /opt/freeradius/exec-ldapupdate.properties
  ln -s /opt/freeradius/exec-ldapupdate.properties $cfg/mods-config/mobileid/exec-ldapupdate.properties
fi

# Disable unneeded modules
[ -f $cfg/mods-enabled/eap ] && rm $cfg/mods-enabled/eap

# Permissions
chown -R :radius $cfg
chown -R :radius /opt/freeradius
chmod +x /opt/freeradius/*.sh
chmod -R +r /opt/freeradius
chmod o-r /opt/freeradius/certs/*
chmod 777 /var/log/radius/