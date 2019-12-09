# Homework #5. SystemD

There are scripts automatically executed during provisioning:

* `watchlog.sh` (uses `wachlog_data`)
* `fcgi.sh` (uses `fcgi_data`)
* `httpd.sh` (uses `httpd_data`)

Below there are instructions how to do such things manually step-by-step.

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


## 3. Extend unit-file `apache httpd`

_Add the `apache httpd` unit file with the ability to run multiple instances of the server with different configurations_  

Copy the unit-file and make a template out of it:
```
[root@lvm system]# cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service

[root@lvm system]# vi /etc/systemd/system/httpd.service
[root@lvm system]# cat /etc/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Create config files for running two web server instances:
```
[root@lvm system]# vi /etc/sysconfig/httpd-first
[root@lvm system]# cat /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf

[root@lvm system]# vi /etc/sysconfig/httpd-second
[root@lvm system]# cat /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf

[root@lvm system]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
[root@lvm system]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```

Modify second config file to setup unique values:
```
[root@lvm system]# vi /etc/httpd/conf/second.conf
[root@lvm system]# cat /etc/httpd/conf/second.conf | grep -Ev ^#
...
Listen 8080
PidFile /var/run/httpd-second.pid
...
```

Check:
```
[root@lvm system]# systemctl start httpd@first
[root@lvm system]# systemctl status httpd@first
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2019-12-09 21:09:44 UTC; 14min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 5205 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@first.service
           ├─5205 /usr/sbin/httpd -DFOREGROUND
           ├─5206 /usr/sbin/httpd -DFOREGROUND
           ├─5207 /usr/sbin/httpd -DFOREGROUND
           ├─5208 /usr/sbin/httpd -DFOREGROUND
           ├─5209 /usr/sbin/httpd -DFOREGROUND
           ├─5210 /usr/sbin/httpd -DFOREGROUND
           └─5211 /usr/sbin/httpd -DFOREGROUND

Dec 09 21:09:44 lvm systemd[1]: Starting The Apache HTTP Server...
Dec 09 21:09:44 lvm httpd[5205]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1. Set the 'ServerName' directive globall... this message
Dec 09 21:09:44 lvm systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.


[root@lvm system]# systemctl start httpd@second
[root@lvm system]# systemctl status httpd@second
● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2019-12-09 21:21:20 UTC; 2min 59s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 5391 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@second.service
           ├─5391 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─5392 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─5393 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─5394 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─5395 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─5396 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           └─5397 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND

Dec 09 21:21:20 lvm systemd[1]: Starting The Apache HTTP Server...
Dec 09 21:21:20 lvm httpd[5391]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1. Set the 'ServerName' directive globall... this message
Dec 09 21:21:20 lvm systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.


[root@lvm system]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080   :::*  users:(("httpd",pid=5397,fd=4),("httpd",pid=5396,fd=4),("httpd",pid=5395,fd=4),("httpd",pid=5394,fd=4),("httpd",pid=5393,fd=4),("httpd",pid=5392,fd=4),("httpd",pid=5391,fd=4))
tcp    LISTEN     0      128      :::80     :::*  users:(("httpd",pid=5211,fd=4),("httpd",pid=5210,fd=4),("httpd",pid=5209,fd=4),("httpd",pid=5208,fd=4),("httpd",pid=5207,fd=4),("httpd",pid
```