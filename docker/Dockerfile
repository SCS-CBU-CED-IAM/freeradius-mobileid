FROM alpine:latest
MAINTAINER Freddy Kaiser <freddy.kaiser@swisscom.com>

# Environment settings and defaults if not passed
ENV AP_ID=mid://dev.swisscom.ch
ENV CLIENT_PWD=testing123
ENV LDAP_SERVER=
ENV LDAP_USERID=
ENV LDAP_PWD=
ENV LDAP_BASEDN=

# Install FreeRADIUS
RUN apk update && apk upgrade \
  && apk add --update freeradius freeradius-ldap freeradius-radclient bash git \
# TODO check if needed:  && openssl && \
# TODO check if needed:  && /bin/sh /etc/raddb/certs/bootstrap && \
  && rm -rf /var/cache/apk/*

# Install Mobile ID module
RUN mkdir -p /opt/freeradius \
  && git clone https://github.com/SCS-CBU-CED-IAM/freeradius-mobileid.git /opt/freeradius/ \
  && chown radius:radius -R /opt/freeradius/

# Expose ports
EXPOSE 1812/udp
EXPOSE 1813/udp

# Define volumes
VOLUME [ "/etc/raddb" ]
VOLUME [ "/opt/freeradius" ]

# Add files
ADD install.sh /opt/install.sh
RUN chmod +x /opt/install.sh

# Run
CMD /opt/install.sh;/usr/sbin/radiusd -X -f