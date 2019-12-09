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


## 2. Rewrite init-script for `spawn-fcgi` to unit-file

_Install `spawn-fcgi` from `epel` and rewrite init-script to unit-file.  
The name of the service should be the same._

Install `spawn-fcgi` and all required packages:
```
[root@lvm system]# yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```

Uncomment lines with variables:
```
[root@lvm system]# vi /etc/sysconfig/spawn-fcgi
[root@lvm system]# cat /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```

Create unit file:
```
[root@lvm system]# vi /etc/systemd/system/spawn-fcgi.service
[root@lvm system]# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Check:
```
[root@lvm system]# systemctl start spawn-fcgi

[root@lvm system]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2019-12-09 20:14:54 UTC; 6s ago
 Main PID: 4575 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─4575 /usr/bin/php-cgi
           ├─4576 /usr/bin/php-cgi
           ├─4577 /usr/bin/php-cgi
           ├─4578 /usr/bin/php-cgi
           ├─4579 /usr/bin/php-cgi
           ├─4580 /usr/bin/php-cgi
           ├─4581 /usr/bin/php-cgi
           ├─4582 /usr/bin/php-cgi
           ├─4583 /usr/bin/php-cgi
           ├─4584 /usr/bin/php-cgi
           ├─4585 /usr/bin/php-cgi
           ├─4586 /usr/bin/php-cgi
           ├─4587 /usr/bin/php-cgi
           ├─4588 /usr/bin/php-cgi
           ├─4589 /usr/bin/php-cgi
           ├─4590 /usr/bin/php-cgi
           ├─4591 /usr/bin/php-cgi
           ├─4592 /usr/bin/php-cgi
           ├─4593 /usr/bin/php-cgi
           ├─4594 /usr/bin/php-cgi
           ├─4595 /usr/bin/php-cgi
           ├─4596 /usr/bin/php-cgi
           ├─4597 /usr/bin/php-cgi
           ├─4598 /usr/bin/php-cgi
           ├─4599 /usr/bin/php-cgi
           ├─4600 /usr/bin/php-cgi
           ├─4601 /usr/bin/php-cgi
           ├─4602 /usr/bin/php-cgi
           ├─4603 /usr/bin/php-cgi
           ├─4604 /usr/bin/php-cgi
           ├─4605 /usr/bin/php-cgi
           ├─4606 /usr/bin/php-cgi
           └─4607 /usr/bin/php-cgi

Dec 09 20:14:54 lvm systemd[1]: Started Spawn-fcgi startup service by Otus.
Dec 09 20:14:54 lvm systemd[1]: Starting Spawn-fcgi startup service by Otus...
```
