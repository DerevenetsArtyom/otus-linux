## 1. Write the service

_Write the service, which will monitor the log every 30 seconds for the presence of the keyword.  
File and word should be set in `/etc/sysconfig`_

To start create a file with the configuration for the service in the directory
`/etc/sysconfig` - the service will take the necessary variables from it.
```
[root@lvm vagrant]# cd /etc/systemd/system/

[root@lvm system]# vi /etc/sysconfig/watchlog

[root@lvm system]# cat /etc/sysconfig/watchlog
# Configuration file for my watchlog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monitored
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Create a script:
```
[root@lvm system]# vi /opt/watchlog.sh

[root@lvm system]# cat /opt/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
    logger "$DATE: I found word, Master!"
else
    exit 0
fi
```

Make the script executable
```
[root@lvm system]# chmod +x /opt/watchlog.sh 
```
 
Create and write some data to `/var/log/watchlog.log`
```
[root@lvm system]# echo "test test ALERT test test" > /var/log/watchlog.log
```

Create unit for the service (in `/etc/systemd/system/`):
```
[root@lvm system]# vi watchlog.service
[root@lvm system]# cat watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

Create unit for timer:
```
[root@lvm system]# vi watchlog.timer
[root@lvm system]# cat watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

Start the timer:
```
[root@lvm system]# systemctl start watchlog.timer

[root@lvm system]# systemctl status watchlog.timer
● watchlog.timer - Run watchlog script every 30 second
   Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: disabled)
   Active: active (waiting) since Sat 2019-12-07 20:43:43 UTC; 21s ago

Dec 07 20:43:43 lvm systemd[1]: Started Run watchlog script every 30 second.
Dec 07 20:43:43 lvm systemd[1]: Starting Run watchlog script every 30 second.
``` 

Check how messages are logged:
```
[root@lvm system]# tail -f /var/log/messages
Dec  7 20:43:50 localhost systemd: Starting watchlog.service...
Dec  7 20:43:50 localhost root: Sat Dec  7 20:43:50 UTC 2019: I found word, Master!
Dec  7 20:43:50 localhost systemd: Started watchlog.service.
Dec  7 20:43:52 localhost systemd: Starting watchlog.service...
Dec  7 20:43:52 localhost root: Sat Dec  7 20:43:52 UTC 2019: I found word, Master!
Dec  7 20:43:52 localhost systemd: Started watchlog.service.
Dec  7 20:44:22 localhost systemd: Starting watchlog.service...
Dec  7 20:44:22 localhost root: Sat Dec  7 20:44:22 UTC 2019: I found word, Master!
Dec  7 20:44:22 localhost systemd: Started watchlog.service.
Dec  7 20:44:52 localhost systemd: Starting watchlog.service...
Dec  7 20:44:52 localhost root: Sat Dec  7 20:44:52 UTC 2019: I found word, Master!
Dec  7 20:44:52 localhost systemd: Started watchlog.service.
```