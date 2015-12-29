FROM alpine:latest
MAINTAINER Freddy Kaiser <freddy.kaiser@swisscom.com>

# Environment settings and defaults if not passed
ENV AP_ID=mid://dev.swisscom.ch
ENV CLIENT_PWD=testing123
ENV LDAP_SERVER=ldap://yourserver.com
ENV LDAP_USERID=SystemLDAP,CN=Users,DC=org,DC=acme,DC=com
ENV LDAP_PWD=ThisMustStaySecret
ENV LDAP_BASEDN=CN=Users,DC=org,DC=acme,DC=ch

# Install FreeRADIUS
RUN apk update && apk upgrade \
  && apk add --update freeradius freeradius-ldap freeradius-radclient bash git \
# TODO check if needed:  && openssl && \
# TODO check if needed:  && /bin/sh /etc/raddb/certs/bootstrap && \
  && rm -rf /var/cache/apk/*

# Install Mobile ID module
ADD install.sh /opt/install.sh
RUN chmod +x /opt/install.sh \
  && mkdir -p /opt/freeradius \
  && git clone https://github.com/SCS-CBU-CED-IAM/freeradius-mobileid.git /opt/freeradius/ \
  && chown radius:radius -R /opt/freeradius/ \
  && /opt/install.sh

# Expose ports
EXPOSE 1812/udp
EXPOSE 1813/udp

# Define volumes
VOLUME [ "/etc/raddb" ]
VOLUME [ "/opt/freeradius" ]

# Run
CMD /usr/sbin/radiusd -f