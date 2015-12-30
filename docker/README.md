# freeradius-mobileid Docker image

!!! WORK IN PROGRESS - DO NOT USE !!!


Lightweight and fast FreeRADIUS 3.x (3.0.6-r1) server Docker image with integrated Mobile ID and LDAP/Active Directory support.

To start: 
```
 $ docker run -d \
   -e AP_ID=mid://dev.swisscom.ch \
   -e AP_PREFIX="Test" \
   -e CERT_FILE= \
   -e CERT_KEY= \
   -e UNIQUEID_CHECK=ifset \
   -e ALLOWED_MCC="000" \
   -e CLIENT_PWD=ThisMustStaySecret \
   -e LDAP_SERVER=yourserver.com \
   -e LDAP_USERID=CN=SystemLDAP,CN=Users,DC=org,DC=acme,DC=com \
   -e LDAP_PWD=ThisMustStaySecret \
   -e LDAP_BASEDN=CN=Users,DC=org,DC=acme,DC=ch \
   -p 1812:1812/udp \
   -p 1813:1813/udp \
   fkaiser/freeradius-mobileid
```

To test:
```
 $ echo "User-Name=+4179xxxxxxx,User-Password=''" | radclient -x -t 120 172.17.0.2 auth ThisMustStaySecret
```

To debug:
```
 $ docker logs freeradius-mobileid
```

