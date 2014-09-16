freeradius-mobileid
===================

Mobile ID module for FreeRADIUS

Refer to the technical documentation for more details:
 * http://swisscom.com/mid


## Install

Checkout the project directly from git under a specific folder:
```
  cd /opt
  git clone https://github.com/SCS-CBU-CED-IAM/freeradius-mobileid.git freeradius
```

Set proper permissions to the FreeRADIUS deamon to access those files. Example:
```
  chown -R freerad:freerad /opt/freeradius
  chmod +x /opt/freeradius/*.sh
```


## Configuration

`<cfg>` is referring to the folder containing the configuration elements. This is depending to the operating system and the chosen installation method. For Linux it should be `/etc/freeradius` and for Windows `C:\FreeRADIUS\etc\raddb`


### Increase maximum request time in radiusd.conf

Edit <cfg>/radiusd.conf and adjust/set following settings to at least
```
  max_request_time = 120
```

### Define additional custom attributes for Mobile ID

Define custom attributes in <cfg>/dictionary
```
ATTRIBUTE    X-MSS-Language    3000    string
ATTRIBUTE    X-MSS-MobileID-SN 3001	string
```

### Create the rlm_exec module file for Mobile ID

Create a rlm_exec module file mobileid in `<cfg>/mods-enabled` based on the sample provided in `samples/modules/` folder:
```
exec mobileid {
    program = '<program> <arg1> <arg2> <...>'
    wait = yes
    timeout = 120
    input_pairs = request
    output_pairs = reply
    shell_escape = yes
}
```

The <program> depends on the operating system and on the location of the files:
 * Linux: program = '/opt/freeradius/exec-mobileid.sh'
 * Windows: program = 'c:\\FreeRADIUS\\var\\mobileid\\exec-mobileid.bat %{Called-Station-Id} %{X-MSS-Language} %{X-MSS-MobileID-SN}'

### Configure your site to use the Mobile ID module

The module can be called in the site configuration like any other standard module (ldap, files, ...) by the name you defined in the rlm_exec file, in our case this would be `mobileid`

Sample site configurations can be found in `samples/sites-available/`

### Define your radius clients (if needed)

To allow RADIUS clients to use your RADIUS server you must define them in `<cfg>/clients.conf`

Example to allow any client from any network to access your FreeRADIUS server (not recommended for production):
```
client 0.0.0.0/0 {
    secret = "thisMustStaySecret”
}
```

### Create the Mobile ID module properties file

Use the `exec-mobileid.properties.sample' and create your own `exec-mobileid.properties` file. Refer to the sample file for the description of the settings.
