# Homework #3. LVM

On the existing volume `/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /`:

* reduce the volume for `/` to 8G
* allocate the volume for `/home`
    * `/home` - make the volume for snapshots
* allocate the volume for `/var`
    * `/var` - create in the mirror
* add the mounting to the `fstab`
* working with snapshots
    * generate files in `/home/`
    * create snapshot
    * delete some files
    * restore removed data from the snapshot

## Reduce the volume for `/` to 8G

Prepare a temporary volume for `/` partition:
``` 
[root@lvm vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

[root@lvm vagrant]# pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g    0 
  /dev/sdb              lvm2 ---    1.00g 1.00g

[root@lvm vagrant]# vgcreate VGroot /dev/sdb
  Volume group "VGroot" successfully created

[root@lvm vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize    VFree   
  VGroot       1   0   0 wz--n- 1020.00m 1020.00m
  VolGroup00   1   2   0 wz--n-  <38.97g       0 

[root@lvm vagrant]# lvcreate -n LVroot -l +100%FREE /dev/VGroot
  Logical volume "LVroot" created.

[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   
  LVroot   VGroot     -wi-a----- 1020.00m
  LogVol00 VolGroup00 -wi-ao----  <37.47g
  LogVol01 VolGroup00 -wi-ao----    1.50g
```

Create a file system on new LV and mount it to transfer data there:
```
[root@lvm vagrant]# mkfs.xfs /dev/VGroot/LVroot

[root@lvm vagrant]# mount /dev/VGroot/LVroot /mnt/
```

Install `xfsdump` (if it's not installed yet) and copy all data from `/` to `/mnt`:
```
[root@lvm vagrant]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt/
...
xfsrestore: Restore Status: SUCCESS

[root@lvm vagrant]# ls /mnt/
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  vagrant  var
```

Restoring grub - reconfigure grub to switch to the new `/` on next system start.  
Simulate the current root -> make `chroot` into it and update grub:
```
[root@lvm vagrant]# for a in /dev/ /proc/ /sys/ /run/ /boot/; do mount --bind /$a /mnt/$a; done

[root@lvm vagrant]# chroot /mnt/

[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

[root@lvm vagrant]# cd /boot/

[root@lvm boot]# for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
...
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Correcting `rd.lvm.lv` in GRUB config:  
In order for the right root to be mounted at boot time, in the file
`/boot/grub2/grub.cfg` replace `rd.lvm.lv=VolGroup00/LogVol00` with `rd.lvm.lv=VGroot/LVroot`:
```
[root@lvm boot]# grep 'rd.lvm.lv=VolGroup00/LogVol00' /boot/grub2/grub.cfg

    linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 ... rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 ...

[root@lvm boot]# vi /boot/grub2/grub.cfg

[root@lvm boot]# grep 'rd.lvm.lv=VGroot/LVroot' /boot/grub2/grub.cfg

    linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 ... rd.lvm.lv=VGroot/LVroot rd.lvm.lv=VolGroup00/LogVol01 ... 

[root@lvm boot]# reboot
```

After rebooting, make sure we did everything right in `lsblk` output:
```
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0    1G  0 disk 
└─VGroot-LVroot         253:0    0 1020M  0 lvm  /
```

Now we need to resize the old LV and return the root to it.  
To do this, remove the old LV size of 40G and create a new size of 8G, 
make the file system and mount it:
```
[root@lvm vagrant]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed

[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0    1G  0 disk 
└─VGroot-LVroot         253:0    0 1020M  0 lvm  /

[root@lvm vagrant]# lvcreate -L 8G -n LogVol00 VolGroup00
  Logical volume "LogVol00" created.

[root@lvm vagrant]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0    8G  0 lvm  
sdb                       8:16   0    1G  0 disk 
└─VGroot-LVroot         253:0    0 1020M  0 lvm  /

[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVol00

[root@lvm vagrant]# mount /dev/VolGroup00/LogVol00 /mnt 

[root@lvm vagrant]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0    8G  0 lvm  /mnt
sdb                       8:16   0    1G  0 disk 
└─VGroot-LVroot         253:0    0 1020M  0 lvm  /
```

Move the root using `xfsdump` and update the GRUB:
```
[root@lvm vagrant]# xfsdump -J - /dev/VGroot/LVroot | xfsrestore -J - /mnt/
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 11 seconds elapsed
xfsrestore: Restore Status: SUCCESS

[root@lvm vagrant]# for a in /dev/ /proc/ /sys/ /run/ /boot/; do mount --bind /$a /mnt/$a; done

[root@lvm vagrant]# chroot /mnt

[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

[root@lvm /]# cd /boot

[root@lvm boot]# for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
...
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

[root@lvm /]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0    8G  0 lvm  /
sdb                       8:16   0    1G  0 disk 
└─VGroot-LVroot         253:0    0 1020M  0 lvm  
```

## Allocate the volume for `/var` in the mirror

Still not rebooting and leaving the `chroot` - we can also move `/var`.  
Create a mirror on two identical disks:
```
[root@lvm /]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.

[root@lvm /]# pvs
  PV         VG         Fmt  Attr PSize    PFree   
  /dev/sda3  VolGroup00 lvm2 a--   <38.97g  <29.47g
  /dev/sdb   VGroot     lvm2 a--  1020.00m       0 
  /dev/sdc   VGvar      lvm2 a--  1020.00m 1020.00m
  /dev/sdd   VGvar      lvm2 a--  1020.00m 1020.00m
  
[root@lvm /]# vgcreate VGvar /dev/sdc /dev/sdd
  Volume group "VGvar" successfully created

[root@lvm /]# vgs
  VG         #PV #LV #SN Attr   VSize    VFree  
  VGroot       1   1   0 wz--n- 1020.00m      0 
  VGvar        2   0   0 wz--n-    1.99g   1.99g
  VolGroup00   1   2   0 wz--n-  <38.97g <29.47g

[root@lvm /]# lvcreate -L 950M -m1 -n LVvar VGvar
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "LVvar" created.

[root@lvm /]# lvs
  LV       VG         Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LVroot   VGroot     -wi-ao---- 1020.00m                                                    
  LVvar    VGvar      rwi-a-r---  952.00m                                    100.00          
  LogVol00 VolGroup00 -wi-ao----    8.00g                                                    
  LogVol01 VolGroup00 -wi-ao----    1.50g    
```

Create a file system on it and move `/var` there:
```
[root@lvm /]# mkfs.ext4 /dev/VGvar/LVvar 

[root@lvm /]# mount /dev/VGvar/LVvar /mnt
```

... and move data to prepared partition
```
[root@lvm /]# rsync -PavHxXAS /var/ /mnt/
sent 115,748,592 bytes  received 278,110 bytes  33,150,486.29 bytes/sec
total size is 115,299,476  speedup is 0.99
```

Make a backup for old `/var/` and mount new `var` to `/var/` directory:
```
[root@lvm /]# mkdir /tmp/var; mv /var/* /tmp/var/

[root@lvm /]# ls /var/ -al
total 4
drwxr-xr-x.  2 root root  22 Nov 27 17:39 .
drwxr-xr-x. 18 root root 239 Nov 27 17:25 ..
-rw-r--r--.  1 root root 163 May 12  2018 .updated

[root@lvm /]# umount /mnt

[root@lvm /]# mount /dev/VGvar/LVvar /var
```

Change `fstab` for the automatic mounting of `/var`: 
```
[root@lvm /]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab

[root@lvm /]# grep var /etc/fstab
UUID="4a6d7fce-bebd-4e6d-997f-25aa0ebf6055" /var ext4 defaults 0 0
```

After that we can successfully reboot in the new (reduced root) and check the results.  
The root is truncated to 8Gb, var in the mirror:
```
[root@lvm vagrant]# reboot

[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0    1G  0 disk 
└─VGroot-LVroot         253:7    0 1020M  0 lvm  
sdc                       8:32   0    1G  0 disk 
├─VGvar-LVvar_rmeta_0   253:2    0    4M  0 lvm  
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_0  253:3    0  952M  0 lvm  
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VGvar-LVvar_rmeta_1   253:4    0    4M  0 lvm  
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_1  253:5    0  952M  0 lvm  
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
```

It remains to delete the unnecessary volume group and logical volume:
```
[root@lvm vagrant]# lvremove /dev/VGroot/LVroot
  Logical volume "LVroot" successfully removed

[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LVvar    VGvar      rwi-aor--- 952.00m                                    100.00          
  LogVol00 VolGroup00 -wi-ao----   8.00g                                                    
  LogVol01 VolGroup00 -wi-ao----   1.50g    

[root@lvm vagrant]# vgremove /dev/VGroot
  Volume group "VGroot" successfully removed

[root@lvm vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree  
  VGvar        2   1   0 wz--n-   1.99g 128.00m
  VolGroup00   1   2   0 wz--n- <38.97g <29.47g

[root@lvm vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.

[root@lvm vagrant]# pvs
  PV         VG         Fmt  Attr PSize    PFree  
  /dev/sda3  VolGroup00 lvm2 a--   <38.97g <29.47g
  /dev/sdc   VGvar      lvm2 a--  1020.00m  64.00m
  /dev/sdd   VGvar      lvm2 a--  1020.00m  64.00m

[root@lvm vagrant]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0    1G  0 disk 
sdc                       8:32   0    1G  0 disk 
├─VGvar-LVvar_rmeta_0   253:2    0    4M  0 lvm  
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_0  253:3    0  952M  0 lvm  
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VGvar-LVvar_rmeta_1   253:4    0    4M  0 lvm  
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_1  253:5    0  952M  0 lvm  
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
```

## Allocate the volume for `/home`

Allocate the volume for `/home` in the same way we did for `/var`:
```
[root@lvm vagrant]# lvcreate -L 2G -n LVhome VolGroup00
  Logical volume "LVhome" created.

[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LVhome

[root@lvm vagrant]# mount /dev/VolGroup00/LVhome /mnt

[root@lvm vagrant]# cp -aR /home/* /mnt/

[root@lvm vagrant]# rm -rf /home/*

[root@lvm vagrant]# umount /mnt

[root@lvm vagrant]# mount /dev/VolGroup00/LVhome /home
```

Change `fstab` for the automatic mounting of `/home`: 
```
[root@lvm vagrant]# echo "`blkid | grep home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab

[root@lvm vagrant]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LVhome   253:7    0    2G  0 lvm  /home
sdb                       8:16   0    1G  0 disk 
sdc                       8:32   0    1G  0 disk 
├─VGvar-LVvar_rmeta_0   253:2    0    4M  0 lvm  
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_0  253:3    0  952M  0 lvm  
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
sdd                       8:48   0    1G  0 disk 
├─VGvar-LVvar_rmeta_1   253:4    0    4M  0 lvm  
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_1  253:5    0  952M  0 lvm  
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
```


## `/home` - make the volume for snapshots

Create some files in `/home/`:
```
[root@lvm vagrant]# touch /home/file{1..20}
```

Make the snapshot:
```
[root@lvm vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LVhome
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.

[root@lvm vagrant]# lsblk 
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0   40G  0 disk 
└─sda3                         8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00      253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01      253:1    0  1.5G  0 lvm  [SWAP]
  ├─VolGroup00-LVhome-real   253:8    0    2G  0 lvm  
  │ ├─VolGroup00-LVhome      253:7    0    2G  0 lvm  /home
  │ └─VolGroup00-home_snap   253:10   0    2G  0 lvm  
  └─VolGroup00-home_snap-cow 253:9    0  128M  0 lvm  
    └─VolGroup00-home_snap   253:10   0    2G  0 lvm  
```

Remove some files:
```
[root@lvm vagrant]# rm -f /home/file{11..20}

[root@lvm vagrant]# ls /home
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9  vagrant
```

Process of snapshot restoring:
```
[root@lvm vagrant]# umount /home

[root@lvm vagrant]# lvconvert --merge /dev/VolGroup00/home_snap 
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LVhome: Merged: 100.00%

[root@lvm vagrant]# mount /home

[root@lvm vagrant]# ls /home/
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9  vagrant
```