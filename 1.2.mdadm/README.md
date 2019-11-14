# How to fail and recover RAID

## Manual failing

You can do this, by "failing" one of the block devices:  
```
# mdadm --fail /dev/md0 /dev/sdd  
mdadm: set /dev/sdd faulty in /dev/md0
```

Let's see how this affects RAID:  
`# mdadm --detail /dev/md0`  

      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent
             State : clean, degraded 
    Active Devices : 1
    Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       64        1      active sync   /dev/sde

       0       8       48        -      faulty   /dev/sdd

## Recovering broken disk

Remove the "broken" disk from the array:  
```
# mdadm /dev/md0 --remove /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md0
```

Let's imagine that we've inserted a new disk into the server and we need
will add it to the RAID. Does it this way:
```
# mdadm /dev/md0 --add /dev/sdd  
mdadm: added /dev/sdd
```

Now you could verify that everything is working fine with one of these commands:
```
# cat /proc/mdstat
# mdadm --detail /dev/md0
```
