freeradius-mobileid
===================

Mobile ID module for FreeRADIUS.

Refer to the technical documentations at [Mobile ID](http://swisscom.com/mid "Mobile ID") for complementary informations. Especially the:
* Mobile ID RADIUS integration guide
* Mobile ID client reference guide


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

1. Create the Mobile ID module properties file

Use the `exec-mobileid.properties.sample` and create your own `exec-mobileid.properties` file. Refer to the [sample file](exec-mobileid.properties.sample) for the settings.


2. Increase maximum request time in radiusd.conf

Edit <cfg>/radiusd.conf and increase the `max_request_time` to at least 120 seconds:
```
  max_request_time = 120
```

3. Define additional custom attributes for Mobile ID

Define custom attributes in <cfg>/dictionary
```
ATTRIBUTE  X-MSS-Language     3000  string
ATTRIBUTE  X-MSS-MobileID-SN  3001  string
```

4. Create the rlm_exec module file for Mobile ID

Create a rlm_exec module file mobileid in `<cfg>/mods-enabled` based on the sample provided in [samples/modules/](samples/modules)

The <program> depends on the operating system and on the location of the files:
 * Linux: program = '/opt/freeradius/exec-mobileid.sh'
 * Windows: program = 'c:\\FreeRADIUS\\var\\mobileid\\exec-mobileid.bat %{Called-Station-Id} %{X-MSS-Language} %{X-MSS-MobileID-SN}'
 
5. Configure your site to use the Mobile ID module

The module can be called in the site configuration like any other standard module (ldap, files, ...) by the name you defined in the rlm_exec file, in our case this would be `mobileid`

Sample site configurations can be found in [samples/sites-available](samples/sites-available)

6. Define user attributes related to the Mobile ID module

Adjust your user store like `<cfg>/users` with proper MID attributes according to the Mobile ID module. The values that have to be set are:
* `CALLED-STATION-ID`: the mobile phone number of the Mobile ID user
* `X-MSS-LANGUAGE`: the language for the call (defaults to EN if unset or invalid)
* `X-MSS-MOBILEID-SN`: the related SerialNumber in the DN of the Mobile ID user (optional)

Sample user file can be found in [samples/](samples/users.sample).

## ...


