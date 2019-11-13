#!/usr/bin/env bash


echo -e "***** Create RAID 1 using '/dev/sdd' and '/dev/sde'\n"
yes | mdadm --create --verbose /dev/md0 --level 1 -n 2 /dev/sdd /dev/sde


echo -e "***** Create configuration file in /etc/mdadm/mdadm.conf\n"
mkdir /etc/mdadm/
touch /etc/mdadm/mdadm.conf

echo -e "***** Add info about partitions into /etc/mdadm/mdadm.conf\n"
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

echo -e "***** Create GPT layout on RAID\n"
parted -s /dev/md0 mklabel gpt

echo -e "***** Create partitions on RAID\n"
parted /dev/md0 mkpart primary ext4 0% 50%
parted /dev/md0 mkpart primary ext4 50% 100%

echo -e "***** Create file systems on these partitions\n"
mkfs.ext4 /dev/md0p1
mkfs.ext4 /dev/md0p2

echo -e "***** Mount these partitions to directories\n"
mkdir -p /raid/part1 /raid/part2
mount /dev/md0p1 /raid/part1
mount /dev/md0p2 /raid/part2
