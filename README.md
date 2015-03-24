freeradius-mobileid
===================

Mobile ID module for FreeRADIUS.

Refer to the technical documentations at [Mobile ID](http://swisscom.com/mid "Mobile ID") for complementary informations. Especially the:
* Mobile ID RADIUS integration guide
* Mobile ID Client reference guide


## Install

Checkout the project directly from git under a specific folder:
```
  cd /opt
  git clone https://github.com/SCS-CBU-CED-IAM/freeradius-mobileid.git freeradius
```

## Configuration

`<cfg>` is referring to the folder containing the configuration elements. This is depending to the operating system and the chosen installation method. For Linux it should be `/etc/freeradius` or `/etc/raddb` and for Windows `C:\FreeRADIUS\etc\raddb`

### Create the Mobile ID module properties file and test it

Use the `exec-mobileid.properties.sample` and create your own `exec-mobileid.properties` file. Refer to the [sample file](exec-mobileid.properties.sample) for the settings.

At this point you can test the module itself with proper command line parameters:

Examples:  
```
./exec-mobileid.sh +41791234567 
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88"

./exec-mobileid.sh +41791234567 de 
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88"

./exec-mobileid.sh +41791234567 de MIDCHEGU8GSH6K88 
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88"

./exec-mobileid.sh +41791234567 de MIDCHEGU8GSH6K88 
Reply-Message:="The request has been canceled by the user."
```

### Increase maximum request time in radiusd.conf

Edit <cfg>/radiusd.conf and increase the `max_request_time` to at least 120 seconds: `max_request_time = 120`

### Define additional custom attributes for Mobile ID

Define custom attributes in `<cfg>/dictionary`

```
ATTRIBUTE  X-MSS-Language     3000  string
ATTRIBUTE  X-MSS-MobileID-SN  3001  string
```

### Create the rlm_exec module file for Mobile ID

Create a rlm_exec module file exec_mobileid in `<cfg>/mods-available` based on the sample provided in [samples/modules/exec_mobileid](samples/modules/exec_mobileid) and make it available over a symlink in `<cfg>/mods-enabled`.

Note: On older distributions, the `<cfg>/mods-available` may not be present and the relevant place will be `<cfg>/modules`

The <program> depends on the operating system and on the location of the files:
 * Linux: `program = '/opt/freeradius/exec-mobileid.sh'`
 * Windows: `program = 'c:\\FreeRADIUS\\var\\mobileid\\exec-mobileid.bat %{Called-Station-Id} %{X-MSS-Language} %{X-MSS-MobileID-SN}'`
 
### Configure your site to use the Mobile ID module

The module can be called in the site configuration like any other standard module (ldap, files, ...) by the name you defined in the rlm_exec file, in our case this would be `mobileid`

Sample site configurations can be found in [samples/sites-available](samples/sites-available)

### Define user attributes related to the Mobile ID module

Adjust your user store like `<cfg>/users` with proper MID attributes according to the Mobile ID module. The values that have to be set are:
* `CALLED-STATION-ID`: the mobile phone number of the Mobile ID user
* `X-MSS-LANGUAGE`: the language for the request to the Mobile ID user (defaults to EN if unset or invalid)
* `X-MSS-MOBILEID-SN`: the unique Mobile ID serial number that must be verified in the response (optional)

Sample user file can be found here [samples/](samples/users.sample).

### Permissions

Set proper permissions to the FreeRADIUS daemon to access those files. Example:
```
  # FreeRADIUS Server configuration
  sudo chown -R :freerad /etc/freeradius

  # FreeRADIUS Mobile ID Module
  sudo chown -R :freerad /opt/freeradius
  ## Execution flag for the scripts
  sudo chmod +x /opt/freeradius/*.sh
  ## Everyone can read all
  sudo chmod -R +r /opt/freeradius
  ## but others should not be able to read the client certificate
  sudo chmod o-r /opt/freeradius/certs/*
```

The group name is depending on the Linux distribution. In general it's either `freerad` or `radiusd`.

### Testing

Start FreeRADIUS and test it. Rather than launching the FreeRADIUS over the service, start the daemon from the console in debug mode: 
```
sudo service freeradius stop
sudo freeradius –X -f
```

The service name is depending on the Linux distribution. In general it's either `freeradius`or `radiusd`.


An easy way to test your RADIUS server is by using the FreeRADIUS provided radclient tool: 
`echo "User-Name=+4179xxxxxxx,User-Password=''" | radclient -t 120 localhost auth testing123`

## Advanced configuration

### Verification of the actual Mobile ID serial number

Refer to the `UNIQUEID_CHECK` setting of [sample file](exec-mobileid.properties.sample) for the possible verifications. By default the verification will only be done if a value has been set in `X-MSS-MobileID-SN`.

### Returned value pair `X-MSS-MobileID-SN`

The actual SerialNumber of the DN from the related Mobile ID user will be set as `X-MSS-MobileID-SN` over the output pairs. This attribute `%{reply:X-MSS-MobileID-SN}` can be used for further processing if needed.

### Updating LDAP/AD with initial/current 'X-MSS-MobileID-SN' value

Updating the related user entry with initial/current 'X-MSS-MobileID-SN' value can be done by calling the rlm_exec module exec_ldapupdate. 

1) Use the `exec-ldapupdate.properties.sample` and create your own `exec-ldapupdate.properties` file. Refer to the [sample file](exec-ldapupdate.properties.sample) for the settings. 

At this point you can test the module itself with proper command line parameters. Examples:  
```
./exec-ldapupdate.sh john.doe MIDCHEGU8GSH6K88
exec-ldapupdate::INFO: Searching for (&(objectclass=user)(objectCategory=person)(sAMAccountName=john.doe))
exec-ldapupdate::INFO: Changing msNPCallingStationID on entry CN=John Doe,CN=Users,DC=org,DC=cartel,DC=ch with value MIDCHEGU8GSH6K88
exec-ldapupdate::INFO: RC=0

./exec-ldapupdate.sh johndoe MIDCHEGU8GSH6K88
exec-ldapupdate::INFO: Searching for (&(objectclass=user)(objectCategory=person)(sAMAccountName=johndoe))
exec-ldapupdate::INFO: No entry johndoe found
exec-ldapupdate::INFO: RC=0
```

2) Create a rlm_exec module file exec_ldapupdate in `<cfg>/mods-available` based on the sample provided in [samples/modules/exec_ldapupdate](samples/modules/exec_ldapupdate) and make it available over a symlink in `<cfg>/mods-enabled`.

3) Configure your site to enable this module after the Mobile ID call  
Uncomment the `# mobileid-ldapupdate` in the `post-auth` section to make it active.


### Returned value pair 'Reply-Message'

Relevant end user errors will set the `Reply-Message` attribute over the output pairs. 

Example when the related mobile phone number does not have the Mobile ID option:
```
$echo "User-Name=+41000092105,User-Password=''" | radclient -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message = "Mobile ID has not been ordered or is not activated for this subscriber number. Please visit www.swisscom.ch/mobileid to activate your Mobile ID."
```

Example when the user related security element is not matching:
```
$echo "User-Name=+41791234567,User-Password=''" | radclient -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message = "Error on the Mobile ID serial number. Please contact your system administrator."
```

### Translations

The actual resources are translated in EN, DE, FR, IT and located in the `dictionaries/` [folder](dictionaries/).

### Message to be displayed / signed

The message is set in the translation dictionaries files. It will be prefixed with the `$AP_PREFIX` defined in the .properties file and ending with the #TRANSID#` value.

Example: "myerver.com: Authentication with Mobile ID? (jdclOE)"

### Logging

Up to the point where the properties file is read the verbosity is set to ERROR. After that point the `VERBOSITY` setting of the properties file will take place.

## Known Issues

**Patching rlm_exec for higher `timeout`**

If you get errors like `Child PID 2366 (/opt/freeradius/exec-mobileid.sh) is taking too much time: forcing failure and killing child.` or `timeout configuration value is too high` you have to patch the FreeRADIUS server rlm_exec module to allow higher timeout value. 
Instruction files can be found here [docs/](docs/).

**Mobile ID Request not sent when FreeRADIUS is started as daemon**

`curl` will raise error 7 and you should disable `SELINUX`: 

edit following file `/etc/selinux/config` 
locate following line `SELINUX=enforcing` 
Change this to `SELINUX=disabled` 

A reboot is needed

**OS X 10.x: Requests always fail with MSS error 104: _Wrong SSL credentials_.**

The `curl` shipped with OS X uses their own Secure Transport engine, which broke the --cert option, see: http://curl.haxx.se/mail/archive-2013-10/0036.html

Install curl from Mac Ports `sudo port install curl` or home-brew: `brew install curl && brew link --force curl`.
