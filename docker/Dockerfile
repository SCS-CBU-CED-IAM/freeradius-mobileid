FROM alpine:latest
MAINTAINER Freddy Kaiser <freddy.kaiser@swisscom.com>

# Environment settings and defaults if not passed
ENV AP_ID="mid://dev.swisscom.ch"
ENV AP_PREFIX="Test"
ENV UNIQUEID_CHECK=ifset
ENV ALLOWED_MCC=
ENV CLIENT_PWD=
ENV LDAP_SERVER="ldap://yourserver.com"
ENV LDAP_USERID="SystemLDAP,CN=Users,DC=org,DC=acme,DC=com"
ENV LDAP_PWD="ThisMustStaySecret"
ENV LDAP_BASEDN="CN=Users,DC=org,DC=acme,DC=ch"

# Install FreeRADIUS
RUN apk update && apk upgrade \
  && apk add --update freeradius freeradius-ldap freeradius-radclient bash git openldap-clients libxml2-utils \
  && rm -rf /var/cache/apk/*

# Install Mobile ID module
RUN mkdir -p /opt/freeradius \
  && git clone https://github.com/SCS-CBU-CED-IAM/freeradius-mobileid.git /opt/freeradius/ \
  && chown radius:radius -R /opt/freeradius/

# Add files
ADD install.sh /opt/install.sh
RUN chmod +x /opt/install.sh

# Expose ports
EXPOSE 1812/udp
EXPOSE 1813/udp

# Run
CMD /opt/install.sh;bash
# CMD /opt/install.sh;/usr/sbin/radiusd -f -X

## TODO
# LDAP Update: optional
# + sed -i -e 's/AP_ID=.*/AP_ID=mid://dev.swisscom.ch/' /opt/freeradius/exec-mobileid.properties
#   sed: bad option in substitution expression
#   same for ldap://
