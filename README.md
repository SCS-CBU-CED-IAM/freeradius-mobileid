freeradius-mobileid
===================

Mobile ID module for FreeRADIUS.

Refer to the technical documentations at [Mobile ID](http://swisscom.com/mid "Mobile ID") for complementary informations. Especially the:
* Mobile ID RADIUS integration guide
* Mobile ID Client reference guide


## Install / Update

Checkout the project directly from git under a specific folder:
```
  cd /opt
  git clone https://github.com/SCS-CBU-CED-IAM/freeradius-mobileid.git freeradius
```

To update your local folder with the current repository:
```
  cd /opt/freeradius
  git pull
  # don't forget to update the permissions (see bellow)
```

## Configuration

`<cfg>` is referring to the folder containing the FreeRADIUS configuration elements. This is depending to the operating system and the chosen installation method. For Linux it should be `/etc/freeradius` or `/etc/raddb` and for Windows `C:\FreeRADIUS\etc\raddb`

### Create the Mobile ID module properties file and test it

Copy the `exec-mobileid.properties.sample` to `exec-mobileid.properties` and edit it. Refer to the [sample file](exec-mobileid.properties.sample) for the settings.


At this point you can test the Mobile ID module itself with proper command line parameters. Examples:  
```
./exec-mobileid.sh +41791234567 
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88",

./exec-mobileid.sh +41791234567 de 
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88",

./exec-mobileid.sh +41791234567 de MIDCHEGU8GSH6K88 
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88",

./exec-mobileid.sh +41791234567 de MIDCHEGU8GSH6K88 
Reply-Message:="The request has been canceled by the user.",
```

### Increase maximum request time in radiusd.conf

Edit `<cfg>/radiusd.conf` and increase the `max_request_time` to at least 120 seconds: `max_request_time = 120`

### Define additional custom attributes

Define custom attributes for Mobile ID in `<cfg>/dictionary`

```
# Entry to control the Mobile ID request language
ATTRIBUTE  X-MSS-Language         3000  string

# Entry to control the unique Mobile ID serial number
ATTRIBUTE  X-MSS-MobileID-SN      3001  string

# Subscriber Info value of MCCMNC out of field value 1901
ATTRIBUTE  X-MSS-MobileID-MCCMNC  3002  string
```

### Create a rlm_exec module file for Mobile ID

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
* `X-MSS-LANGUAGE`: the language for the request to the Mobile ID user
* `X-MSS-MOBILEID-SN`: the unique Mobile ID serial number that must be verified in the response (optional)

Sample user file can be found here [samples/](samples/users.sample).

### Permissions

Set proper permissions to the FreeRADIUS daemon to access those files. The group name is depending on the Linux distribution. In general it's either `freerad` or `radiusd`. Example:
```
  # FreeRADIUS Server configuration
  [ -d /etc/freeradius ] && sudo chown -R :freerad /etc/freeradius
  [ -d /etc/raddb ] && sudo chown -R :radiusd /etc/raddb

  # FreeRADIUS Mobile ID Module
  [ -d /etc/freeradius ] && sudo chown -R :freerad /opt/freeradius
  [ -d /etc/raddb ] && sudo chown -R :radiusd /opt/freeradius

  ## Execution flag for the scripts
  sudo chmod +x /opt/freeradius/*.sh

  ## Everyone can read all
  sudo chmod -R +r /opt/freeradius

  ## but others should not be able to read the client certificate
  sudo chmod o-r /opt/freeradius/certs/*
```


### Testing

Start FreeRADIUS and test it. Rather than launching the FreeRADIUS over the service, start the `freeradius` service from the console in debug mode: 
```
sudo service freeradius stop
sudo freeradius –X -f
```
depending on the Linux distribution, the service name may be `radiusd`:
```
sudo service radiusd stop
sudo radiusd –X -f
```


An easy way to test your RADIUS server is by using the FreeRADIUS provided radclient tool: 
````
echo "User-Name=+4179xxxxxxx,User-Password=''" | radclient -x -t 120 localhost auth testing123
````


## Advanced configuration

### Verification of the actual Mobile ID serial number

Refer to the `UNIQUEID_CHECK` setting of [sample file](exec-mobileid.properties.sample) for the possible verifications. By default the verification will only be done if a value has been set in `X-MSS-MobileID-SN`

### Returned value pair `X-MSS-MobileID-SN`

The actual SerialNumber of the DN from the related Mobile ID user will be set as `X-MSS-MobileID-SN` over the output pairs. This attribute `%{reply:X-MSS-MobileID-SN}` can be used for further processing if needed.

### Updating LDAP/AD with initial/current `X-MSS-MobileID-SN` value

Updating the related user entry with initial/current `X-MSS-MobileID-SN` value can be done by calling the rlm_exec module exec_ldapupdate. 

1) Copy the `exec-ldapupdate.properties.sample` to `exec-ldapupdate.properties` and edit it. Refer to the [sample file](exec-ldapupdate.properties.sample) for the settings. 

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

### Subscriber Information

The actual MCC-MNC (http://www.mcc-mnc.com) information will be returned for authorised customers into `X-MSS-MobileID-MCCMNC` for further parsing.
This can be used to restrict the countries from where the users are allowed to login from. For more details, refer to the optional `ALLOWED_MCC` setting in [sample file](exec-mobileid.properties.sample).

Example for Switzerland (228) and Swisscom (01)
```
./exec-mobileid.sh +41791234567 
X-MSS-MobileID-MCCMNC:="22801",
X-MSS-MobileID-SN:="MIDCHEGU8GSH6K88",
```
If not authorised or the information is unknown, then the value will be `X-MSS-MobileID-MCCMNC:="00000",`.

## Additional information

### Returned value pair `Reply-Message`

Relevant end user errors will set the `Reply-Message` attribute over the output pairs. 

Example when the related mobile phone number does not have the Mobile ID option:
```
$echo "User-Name=+41791234567,User-Password=''" | radclient -x -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message:="The subscriber number is not yet activated for Mobile ID. Please visit https://sam.sso.bluewin.ch/registration/MobileId?msisdn=41791234567 to activate your Mobile ID."
```

Example when the user related security element is not matching:
```
$echo "User-Name=+41791234567,User-Password=''" | radclient -x -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message:="Error on the Mobile ID serial number. Please contact your system administrator."
```

### Translations

The actual resources are translated in EN, DE, FR, IT and located in the `dictionaries/` [folder](dictionaries/).

### Message to be displayed / signed

The message is set in the translation dictionaries files. It will be prefixed with the `$AP_PREFIX` defined in the .properties file and ending with the #TRANSID#` value.

Example: "myerver.com: Authentication with Mobile ID? (jdclOE)"

### Logging

Up to the point where the properties file is read the verbosity is set to ERROR. After that point the `VERBOSITY` setting of the properties file will take place.

The logging itself is done to standard error (screen), as well as to the system log.

## Known Issues

**Patching rlm_exec for higher `timeout`**

If you get errors like `Child PID 2366 (/opt/freeradius/exec-mobileid.sh) is taking too much time: forcing failure and killing child.` or `timeout configuration value is too high` you have to patch the FreeRADIUS server rlm_exec module to allow higher timeout value. 
Instruction files can be found here [docs/](docs/).

**Mobile ID Request not sent when FreeRADIUS is started as daemon**

`curl` raises error 7 and/or `exec-mobileid.sh` states about `freeradius:exec-mobileid::ERROR: Error in creating temporary file(s)` 

This issues is solved with the following custom selinux policy:  
`module freeradiusd-v2.1.0;`  
`require {`  
`type tmp_t;`  
`type radiusd_t;`  
`class file`  
`{ write create open }`  
`;`  
`}`  

`\#============= radiusd_t ==============`  
`allow radiusd_t tmp_t:file create;`  
`allow radiusd_t tmp_t:file`  
`{ write open }`  
`; ()`  

The alternative is to disable `SELINUX`: 
- edit following file `/etc/selinux/config` 
- locate following line `SELINUX=enforcing` 
- change this to `SELINUX=disabled` or `SELINUX=permissive` 

A reboot is needed

**OS X 10.x: Requests always fail with MSS error 104: _Wrong SSL credentials_.**

The `curl` shipped with OS X uses their own Secure Transport engine, which broke the --cert option, see: http://curl.haxx.se/mail/archive-2013-10/0036.html

Install curl from Mac Ports `sudo port install curl` or home-brew: `brew install curl && brew link --force curl`.
