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

Define custom attributes in <cfg>/dictionary
```
ATTRIBUTE  X-MSS-Language     3000  string
ATTRIBUTE  X-MSS-MobileID-SN  3001  string
```

### Create the rlm_exec module file for Mobile ID

Create a rlm_exec module file mobileid in `<cfg>/mods-enabled` based on the sample provided in [samples/modules/](samples/modules)

The <program> depends on the operating system and on the location of the files:
 * Linux: program = '/opt/freeradius/exec-mobileid.sh'
 * Windows: program = 'c:\\FreeRADIUS\\var\\mobileid\\exec-mobileid.bat %{Called-Station-Id} %{X-MSS-Language} %{X-MSS-MobileID-SN}'
 
### Configure your site to use the Mobile ID module

The module can be called in the site configuration like any other standard module (ldap, files, ...) by the name you defined in the rlm_exec file, in our case this would be `mobileid`

Sample site configurations can be found in [samples/sites-available](samples/sites-available)

### Define user attributes related to the Mobile ID module

Adjust your user store like `<cfg>/users` with proper MID attributes according to the Mobile ID module. The values that have to be set are:
* `CALLED-STATION-ID`: the mobile phone number of the Mobile ID user
* `X-MSS-LANGUAGE`: the language for the request to the Mobile ID user (defaults to EN if unset or invalid)
* `X-MSS-MOBILEID-SN`: the unique Mobile ID serial number that must be verified in the response (optional)

Sample user file can be found here [samples/](samples/users.sample).

## Advanced configuration

### 'Reply-Message'

Relevant end user errors will set the `Reply-Message` attribute over the output pairs.

Example when the related mobile phone number does not have the Mobile ID option:
```
$echo "User-Name=+41000092105,User-Password=''" | radclient -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message = "Mobile ID has not been ordered or is not activated for this subscriber number. To be able to use Mobile ID, it has to be ordered and activated first."
```

Example when the user cancels the Mobile ID request on his device:
```
$echo "User-Name=+41000092401,User-Password=''" | radclient -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message = "The request has been canceled by the user."
```

Example when the user related security element is not matching:
```
$echo "User-Name=+41791234567,User-Password=''" | radclient -t 120 ...
Received response ID 255, code 3, length = 160
    Reply-Message = "Your unique Mobile ID serial number has changed. Please contact your administrator."
```

### Translations

The actual resources are translated in EN, DE, FR, IT and located in the `dictionaries/` folder.

### Message to be displayed / signed

The message is set in the translation dictionaries files and prefixed with the `$AP_PREFIX` defined in the .properties file.
Example: "myerver.com: Authentication with Mobile ID?"

### Logging

Up to the point where the properties file is read the verbosity is set to ERROR. After that point the `VERBOSITY` setting of the properties file will take place.
