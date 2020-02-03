# Homework #6. Bash scripts

There is the script for cron which sends once an hour to a specified mailbox:
* _X_ IP addresses (with the largest number of requests) with the number of requests since the last run of the script.
* _Y_ of the requested addresses (with the largest number of requests) with the number of requests since the last run of the script.
* all errors since last run.
* a list of all return codes and their number since the last run.

The letter should specify the time range to be processed.
Multistart protection should be implemented with traps.

## Description of files:
* _log_analyzer.sh_ - the main script that performs analysis of the log file.
* _access-4560-644067.log_ - the main log file.
* _report_cron_ - cron file in VM created by Vagrantfile.
* _Vagrantfile_ - Vagrant file, for solution testing.


## How to run:
1. To test the execution, run the VM with `vagrant up`.  
2. Then `vagrant ssh`.  
3. Run `./log-analyzer.sh access-4560-644067.log`  
4. Created `mail_report` file will contain report.  
5. After 5 minutes you could check the mail of the vagrant (or root) user.


## Report (example)
```
### Report statistics ###

Log analize events between 14/Aug/2019:04:12:10 - 15/Aug/2019:00:25:46

Requests count by CODE:
    Code 200 requests count - 498
    Code 301 requests count - 95
    Code 304 requests count - 1
    Code 400 requests count - 7
    Code 403 requests count - 1
    Code 404 requests count - 51
    Code 405 requests count - 1
    Code 499 requests count - 2
    Code 500 requests count - 3

Top 10 User IP by accessing server:
     45   93.158.167.130
     39   109.236.252.130
     37   212.57.117.19
     33   188.43.241.106
     31   87.250.233.68
     24   62.75.198.172
     22   148.251.223.21
     20   185.6.8.9
     17   217.118.66.161
     16   95.165.18.146

Top 10 URL Address:
    157 /
    120 /wp-login.php
     57 /xmlrpc.php
     26 /robots.txt
     12 /favicon.ico
     11 400
      9 /wp-includes/js/wp-embed.min.js?ver=5.0.4
      7 /wp-admin/admin-post.php?page=301bulkoptions
      7 /1
      6 /wp-content/uploads/2016/10/robo5.jpg


All errors list:
    93.158.167.130 [14/Aug/2019:05:02:20 +0300] "GET / HTTP/1.1" 404
    87.250.233.68 [14/Aug/2019:05:04:20 +0300] "GET / HTTP/1.1" 404
    107.179.102.58 [14/Aug/2019:05:22:10 +0300] "GET /wp-content/plugins/uploadify/readme.txt HTTP/1.1" 404
    193.106.30.99 [14/Aug/2019:06:02:50 +0300] "GET /wp-includes/ID3/comay.php HTTP/1.1" 500
    87.250.244.2 [14/Aug/2019:06:07:07 +0300] "GET / HTTP/1.1" 404
    77.247.110.165 [14/Aug/2019:06:13:53 +0300] "HEAD /robots.txt HTTP/1.0" 404
    182.254.243.249 [15/Aug/2019:00:24:38 +0300] "GET /webdav/ HTTP/1.1" 404
    ..............

Last parsed line in log - #670
Line: 66.249.64.204 - - [15/Aug/2019:00:25:46 +0300] "GET / HTTP/1.1" 200 14446 "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"rt=0.270 uct="0.000" uht="0.185" urt="0.270"

Run at Tue Jan 28 20:23:20 UTC 2020
```
