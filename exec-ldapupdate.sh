#!/bin/sh
# exec-ldapupdate.sh
# Script to update LDAP user with proper Mobile ID SerialNumber of the DN
#
#  arg1: User to be found
#  arg2: MobileID SerialNumber
#
# Dependencies: ldapsearch, ldapmodify, sed
#
# License: Licensed under the Apache License, Version 2.0 or later; see LICENSE.md
# Author: Swisscom (Schweiz) AG

# Possible return codes
RLM_MODULE_SUCCESS=0                     # ok: the module succeeded
RLM_MODULE_FAIL=2                        # fail: the module failed
RLM_MODULE_NOTFOUND=7                    # notfound: the user was not found

# Logging functions
VERBOSITY=2                              # Default verbosity to error (can be set by .properties)
silent_lvl=0
inf_lvl=1
err_lvl=2
dbg_lvl=3

inform() { log $inf_lvl "INFO: $@"; }
error() { log $err_lvl "ERROR: $@"; }
debug() { log $dbg_lvl "DEBUG: $@"; }
log() {
  if [ $VERBOSITY -ge $1 ]; then         # Logging to syslog and STDERR
    logger -s "freeradius:exec-ldapupdate::$2"
    if [ "$3" != "" ]; then logger -s "$3" ; fi
  fi
}

# Cleanups of temporary files
cleanups()
{
  [ -w "$TMP" ] && rm $TMP
  [ -w "$TMP.update" ] && rm $TMP.search
  [ -w "$TMP.update" ] && rm $TMP.update
}

# Get the Path of the script
PWD=$(dirname $0)
# Seeds the random number generator from PID of script
RANDOM=$$

# Check the dependencies
for cmd in ldapsearch ldapmodify sed; do
  hash $cmd &> /dev/null
  if [ $? -eq 1 ]; then error "Dependency error: '$cmd' not found" ; fi
done

# Get the params
USERID=$1
UNIQUEID=$2
[ "$USERID" = "" ] && error "Missing arg1: User to be found"
[ "$UNIQUEID" = "" ] && error "Missing arg2: MobileID SerialNumber"

# Read configuration from property file
FILE="$PWD/exec-ldapupdate.properties"
[ -r "$FILE" ] || error "Properties file ($FILE) missing or not readable"
. $PWD/exec-ldapupdate.properties
[ "$server" = "" ] && error "Missing 'server' setting in the properties file ($FILE)"

# Temporary files
TMP=$(mktemp /tmp/_tmp.XXXXXX)           # Request goes here

# Lookup for the user and get the DN
inform "Searching for $filter"
OPT="-LLL"                               # Print responses in LDIF format without comments and version
[ "$server" = "" ] || OPT="$OPT -H $server"         # ldap server
[ "$basedn" = "" ] || OPT="$OPT -b $basedn"         # base DN
[ "$userid" = "" ] || OPT="$OPT -D $userid"         # Bind DN
[ "$password" = "" ] || OPT="$OPT -w $password"     # Password
OPT="$OPT -s sub -z 1"                              # Other options: scope, results, timeout
[ "$timeout" = "" ] || OPT="$OPT -o nettimeout=$timeout"
OPT="$OPT $filter"                                  # Filter
[ "$attributes" = "" ] || OPT="$OPT $attributes"    # and attributes

debug "ldapsearch $OPT"
ldapsearch $OPT > $TMP.search
RC_LDAP=$?

DEBUG_INFO=`cat $TMP.search`
debug ">>> $TMP.search <<<" "$DEBUG_INFO"

if [ "$RC_LDAP" = "0" ]; then            # Parse the search result
  RES_DN=$(sed -n -e 's|dn: ||p' $TMP.search)
  if [ "$RES_DN" != "" ]; then             # Entry found
    inform "Found entry $RES_DN"
      if [ "$UNIQUEID" != "" ]; then         # New value has been passed/set
      inform "Changing $attribute_toupdate on entry $RES_DN with value $UNIQUEID"
      # Updating the entry
      UPDATE="dn: $RES_DN
changetype: modify
replace: $attribute_toupdate
$attribute_toupdate: $UNIQUEID"
      echo "$UPDATE" > $TMP.update

      OPT="-f $TMP.update"                     # File with LDIF content
      [ "$server" = "" ] || OPT="$OPT -H $server"         # ldap server
      [ "$userid" = "" ] || OPT="$OPT -D $userid"         # Bind DN
      [ "$password" = "" ] || OPT="$OPT -w $password"     # Password
      OPT="$OPT -x"                                       # Other options: quiet, timeout
      [ "$timeout" = "" ] || OPT="$OPT -o nettimeout=$timeout"

      debug "ldapmodify $OPT"
      ldapmodify $OPT > /dev/null 2>&1
      RC_LDAP=$?

      DEBUG_INFO=`cat $TMP.update`
      debug ">>> $TMP.update <<<" "$DEBUG_INFO"

      if [ "$RC_LDAP" != "0" ]; then           # Error in ldapmodify
        error "ldapmodify failed with $RC_LDAP"
      fi
    fi
   else                                    # -> entry not found
    inform "No entry $USERID found"
  fi
 else                                    # -> error in ldapsearch
   error "ldapsearch failed with $RC_LDAP"
fi

cleanups                                 # Cleanups

# Allways return succes to avoid login error
RC=$RLM_MODULE_SUCCESS
inform "RC=$RC"

exit $RC

#==========================================================
