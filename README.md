# buildalternbind : building alternative runtime instances of bind #

buildalternbind is a nifty script for building autonomous additionnal runtime
environment for the bind/named DNS-server daemon.
Such additionnal instances are often needed for testing parameters, weird
recursions, local spoofing, local resolutions that must stay private or
daemons whose operations should stay apart of public dns-resolutions, for internal
production environment, or VPN zones.
It's also convenient to mitigate restart troubles within different sets
of zone deliveries

# Usage #
### prerequesites ###
the script needs some original content of /etc/bind configuration directory
with permissions correctly set. For that purpose a "template" directory
named /etc/bind-dist should lay in /etc, usually a fresh copy of the
distribution-supplied directory is the best, right after installing the
package bind9, simply copy it :
```
cp -a /etc/bind /etc/bind-dist
```
### regular use ###
Then, in order to create a new instance called mytest, one should simply :
```
buildalternbind.sh mytest 954
```
The 954 is the dedicated port that the daemon would listen on 127.0.0.1:954
for rndc controlling. it must of course be unique on one machine.
Then tuning the listen and like entries of /etc/bind-mytest/named.conf.options is
mandatory. Be carefull of default bind settings that listen on all available
addresses that will certainly collide here !
```
# launch the service for checking :
service bind-mytest start ; less +F /var/log/daemon.log
```
If everything suits your need, install it for good :
```
update-rc.d bind9-mytest start 17 2 3 4 5 . stop 02 0 1 6 .
```


### permission troubles with apparmor ###

At will you may restart the apparmord to activate the mandatory changes if needed :
```
# check the diff between old and new policies :
vimdiff usr.sbin.named-orig-20140107-1324 /etc/apparmor.d/usr.sbin.named

# if needed (if the new instance choke on reading the config file with
# permission troubles, and apparmor is enabled on the machine)
service apparmor reload
```

# output example : #
buildalternbind checks for previous instances installation and needed source templates
before processing any addition.
It then reports all new files in /etc, diffs in apparmor (if suitable) and updaterc
suggestions :
```
root@machine#  ./buildalternbind.sh mytest 950
wrote key file "rndc.key"
-rw-r--r-- 1 root root  601 2014-01-08 13:36 /etc/bind-mytest/bind.keys
-rw-r--r-- 1 root root  237 2014-01-08 13:36 /etc/bind-mytest/db.0
-rw-r--r-- 1 root root  271 2014-01-08 13:36 /etc/bind-mytest/db.127
-rw-r--r-- 1 root root  237 2014-01-08 13:36 /etc/bind-mytest/db.255
-rw-r--r-- 1 root root  353 2014-01-08 13:36 /etc/bind-mytest/db.empty
-rw-r--r-- 1 root root  270 2014-01-08 13:36 /etc/bind-mytest/db.local
-rw-r--r-- 1 root root 2940 2014-01-08 13:36 /etc/bind-mytest/db.root
drwxrws--- 2 bind bind 4096 2014-01-08 13:36 /etc/bind-mytest/master
-rw-r--r-- 1 root bind  491 2014-01-08 13:36 /etc/bind-mytest/named.conf
-rw-r--r-- 1 root bind  525 2014-01-08 13:36 /etc/bind-mytest/named.conf.default-zones
-rw-r--r-- 1 root bind  325 2014-01-08 13:36 /etc/bind-mytest/named.conf.local
-rw-r--r-- 1 root bind  172 2014-01-08 13:36 /etc/bind-mytest/named.conf.local-noky
-rw-r--r-- 1 root bind  579 2014-01-08 13:36 /etc/bind-mytest/named.conf.options
-rw-r--r-- 1 root bind  579 2014-01-08 13:36 /etc/bind-mytest/named.conf.options-nopid
-rw-r--r-- 1 root bind  215 2014-01-08 13:36 /etc/bind-mytest/rndc.conf
-rw-r----- 1 bind bind   77 2014-01-08 13:36 /etc/bind-mytest/rndc.key
drwxrws--- 2 bind bind 4096 2014-01-08 13:36 /etc/bind-mytest/slave
-rw-r--r-- 1 root root 1443 2014-01-08 13:36 /etc/bind-mytest/zones.rfc1918
-rw-r--r-- 1 root root  185 2014-01-08 13:36 /etc/default/bind9-mytest
-rwxr-xr-x 1 root root 3311 2014-01-08 13:36 /etc/init.d/bind9-mytest

apparmord additions !!! :
diff /etc/apparmor/usr.sbin.named-orig-20140108-1336 /etc/apparmor.d/usr.sbin.named
54a55,62
>   # addition for instance bind9-mytest
>   /etc/bind-mytest/** r,
>   /var/lib/bind-mytest/ rw,
>   /var/lib/bind-mytest/** rw,
>   /var/cache/bind-mytest/** rw,
>   /var/cache/bind-mytest/ rw,
>   /{,var/}run/named-mytest/named.pid w,
>   /{,var/}run/named-mytest/session.key w,

apply with : service apparmor reload


in order to activate bind9-mytest, you may :
update-rc.d bind9-mytest start 17 2 3 4 5 . stop 02 0 1 6 .

done

```

2008 - Jean-Daniel Pauget
