#!/bin/bash

cfg=/etc/raddb
opt=/opt/freeradius

# Clients
if [ -e $cfg/clients.conf ]; then
  [ -f $cfg/clients.conf.ori ] || cp $cfg/clients.conf $cfg/clients.conf.ori
  cp $opt/samples/clients.sample $cfg/clients.conf
  sed -i -e "s/testing123/$CLIENT_PWD/" $cfg/clients.conf
fi

# Server config
if [ -e $cfg/radiusd.conf ]; then
  sed -i -e "s/max_request_time.*/max_request_time = 120/" $cfg/radiusd.conf
fi

# Sites
if [ ! -e $cfg/sites-enabled/mobileid ]; then
  rm $cfg/sites-enabled/*
  cp $opt/samples/sites-available/mobileid-docker $cfg/sites-available/mobileid
  ln -s $cfg/sites-available/mobileid $cfg/sites-enabled/mobileid
fi

# Dictionary
[ -f $cfg/dictionary.ori ] || cp $cfg/dictionary $cfg/dictionary.ori
cp $opt/samples/dictionary.sample $cfg/dictionary

# LDAP
[ -f $cfg/mods-available/ldap.ori ] || cp $cfg/mods-available/ldap $cfg/mods-available/ldap.ori
[ -f $cfg/mods-enabled/ldap ] && rm $cfg/mods-enabled/ldap
cp $opt/samples/ldap.sample $cfg/mods-available/ldap
sed -i -e "s/%LDAP_SERVER%/\"$LDAP_SERVER\"/g" $cfg/mods-available/ldap
sed -i -e "s/%LDAP_USERID%/\"$LDAP_USERID\"/g" $cfg/mods-available/ldap
sed -i -e "s/%LDAP_PWD%/\"$LDAP_PWD\"/g" $cfg/mods-available/ldap
sed -i -e "s/%LDAP_BASEDN%/\"$LDAP_BASEDN\"/g" $cfg/mods-available/ldap
ln -s $cfg/mods-available/ldap $cfg/mods-enabled/ldap

# Mobile ID
if [ ! -e $cfg/mods-available/exec_mobileid ]; then
  cp $opt/samples/modules/* $cfg/mods-available/
  ln -s $cfg/mods-available/exec_mobileid $cfg/mods-enabled/exec_mobileid
  ln -s $cfg/mods-available/exec_ldapupdate $cfg/mods-enabled/exec_ldapupdate
fi

[ -d $cfg/mods-config/mobileid ] || mkdir $cfg/mods-config/mobileid
if [ ! -e $opt/exec-mobileid.properties ]; then
  cp $opt/exec-mobileid.properties.sample $opt/exec-mobileid.properties
  sed -i -e "s/AP_ID=.*/AP_ID=$AP_ID/" $opt/exec-mobileid.properties
  sed -i -e "s/AP_PREFIX=.*/AP_PREFIX=$AP_PREFIX/" $opt/exec-mobileid.properties
  [ "$UNIQUEID_CHECK" != ""] && sed -i -e "s/UNIQUEID_CHECK=.*/UNIQUEID_CHECK=$UNIQUEID_CHECK/" $opt/exec-mobileid.properties
  [ "$ALLOWED_MCC" != ""] && sed -i -e "s/# ALLOWED_MCC=.*/ALLOWED_MCC=$ALLOWED_MCC/" $opt/exec-mobileid.properties
  ## TODO: Add key and crt
  ln -s $opt/exec-mobileid.properties $cfg/mods-config/mobileid/exec-mobileid.properties
fi
if [ ! -e $opt/exec-ldapupdate.properties ]; then
  cp $opt/exec-ldapupdate.properties.sample $opt/exec-ldapupdate.properties
  sed -i -e "s/server=.*/server=$LDAP_SERVER/" $opt/exec-ldapupdate.properties
  sed -i -e "s/userid=.*/userid=$LDAP_USERID/" $opt/exec-ldapupdate.properties
  sed -i -e "s/password=.*/password=$LDAP_PWD/" $opt/exec-ldapupdate.properties
  sed -i -e "s/basedn=.*/basedn=$LDAP_BASEDN/" $opt/exec-ldapupdate.properties
  ln -s $opt/exec-ldapupdate.properties $cfg/mods-config/mobileid/exec-ldapupdate.properties
fi

# Disable unneeded modules
[ -f $cfg/mods-enabled/eap ] && rm $cfg/mods-enabled/eap

# Permissions
chown -R :radius $cfg
chown -R :radius $opt
chmod +x $opt/*.sh
chmod -R +r $opt
chmod o-r $opt/certs/*
chmod 777 /var/log/radius/