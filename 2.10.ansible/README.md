# Homework 09. First steps with Ansible

Prepare a stand on Vagrant with at least one server.  
On this server, using Ansible, you must deploy `nginx` with the following conditions:
- you need to use the yum/apt module
- the configuration files should be taken from the jinja2 template with the following variables
- after installation, nginx should be in `enabled` mode (systemd)
- `notify` should be used to start nginx after installation
- the site should listen on a non-standard port - 8080, for this use variables in Ansible  
*To do all this using the Ansible role*

---

## Preparations for launch
We create an environment from a prepared vagrant file.  
```
vagrant up --no-provision
```

Let's check which port is used for access  
```
vagrant ssh-config

Host nginx
  HostName 127.0.0.1
  User vagrant
  Port 2222
  ...
```

If the port is not 2222, then we will make the corresponding changes to the file
```
cat hosts

[web]
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key
```

And we launch
```
vagrant provision
...
nginx : ok=6  changed=5  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```


## Description
In the running Virtual Machine, the script has performed the required actions.

Check that port 8080 is listening on nginx
```
vagrant ssh

[vagrant@nginx ~]$ sudo ss -tulnp|grep 8080
tcp LISTEN 0 128 *:8080 *:* users:(("nginx",pid=4791,fd=6),("nginx",pid=4717,fd=6))
```

And also that the nginx service is enabled.
```
[vagrant@nginx ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2020-02-24 17:37:38 UTC; 2min 22s ago
  Process: 4790 ExecReload=/bin/kill -s HUP $MAINPID (code=exited, status=0/SUCCESS)
  Process: 4715 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 4712 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 4711 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 4717 (nginx)
   CGroup: /system.slice/nginx.service
           ├─4717 nginx: master process /usr/sbin/nginx
           └─4791 nginx: worker process

Feb 24 17:37:38 nginx systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 24 17:37:38 nginx nginx[4712]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 24 17:37:38 nginx nginx[4712]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 24 17:37:38 nginx systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
Feb 24 17:37:38 nginx systemd[1]: Started The nginx HTTP and reverse proxy server.
Feb 24 17:37:38 nginx systemd[1]: Reloaded The nginx HTTP and reverse proxy server.
```