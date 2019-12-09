#!/bin/bash

###################################
#Copy prepared files

SRC=/vagrant/wachlog_data
chmod a+x $SRC/watchlog.sh

mv $SRC/watchlog /etc/sysconfig/
mv $SRC/watchlog.log  /var/log/
mv $SRC/watchlog.sh /opt/
mv $SRC/watchlog.service /etc/systemd/system/
mv $SRC/watchlog.timer /etc/systemd/system/

###################################
#Run timer and service

sudo systemctl enable watchlog.timer
sudo systemctl start watchlog.timer
sudo systemctl enable watchlog.service
sudo systemctl start watchlog.service