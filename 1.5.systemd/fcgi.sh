#!/bin/bash

###################################
#Install spawn-fcgi and all required packages:

yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y

###################################
#Uncomment lines with variables:

sed -i '/SOCKET=/s/^#//g' /etc/sysconfig/spawn-fcgi
sed -i '/OPTIONS=/s/^#//g' /etc/sysconfig/spawn-fcgi

###################################
#Copy prepared init file

SRC=/vagrant/fcgi_data
mv $SRC/spawn-fcgi.service /etc/systemd/system/

###################################
#Statr the service

sudo systemctl enable spawn-fcgi
sudo systemctl start spawn-fcgi