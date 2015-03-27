Additional documentation
========================

## Patching FreeRADIUS in regards to the rlm_exec timeout

* [Patching-CentOS-7.0-1406.txt](Patching CentOS-7.0-1406)
* [Patching-Ubuntu-14.04.1.txt](Patching Ubuntu-14.04.1)
* [Patching-Ubuntu-14.04.1.txt](Patching Ubuntu-14.10)


Following source file needs to be adjusted during the patching process.

### FreeRADIUS versions prior 2.1.10Edit `src/main/exec.c` and change the following lines in order to extend the 10 seconds to 120. From:````  if (elapsed.tv_sec >= 10) goto too_long;  ...  when.tv_sec = 10;````to:````  if (elapsed.tv_sec >= 120) goto too_long;  ...  when.tv_sec = 120;````
### FreeRADIUS versions 2.1.12 and higher
Edit `src/modules/rlm_exec/rlm_exec.c`, around line 283, in order to increase the maximum from 30 to 120. From:````  if (inst->timeout > 30) {    cf_log_err_cs(conf, "Timeout '%d' is too large (maximum: 30)", inst->timeout);    return -1;  }````to:````  if (inst->timeout > 120) {    cf_log_err_cs(conf, "Timeout '%d' is too large (maximum: 120)", inst->timeout);    return -1;  }````