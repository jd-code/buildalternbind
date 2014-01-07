#!/bin/sh

BINDTAG="${1}"
RNDCPORT="${2}"

usage () {
    echo "$0 : buildalternbind.sh  :  builids an alternate bind context"
    echo "   usage example : buildalternbind.sh InstanceName 954"
    echo "   will copy from existing /etc/bind to /etc/bind-InstanceName"
    echo "   everything for a suitable service (called bind9-InstanceName)"
    echo "   masterised via the rndc port 127.0.0.1:954"
}

checkfordisttemplates () {

    SILENCY="$1"

    for TEMPLATESRC in		\
	/etc/bind-dist		\
	/etc/init.d/bind9
    do
	if [ ! -e "${TEMPLATESRC}" ]
	then
	    if [ "E$SILENCY" = "EDISPLAYALL" ]
	    then
		echo "source ${TEMPLATESRC} is missing"
	    else
		return 0
	    fi
	fi
    done
    return 1
}

checkifpreviousexist () {

    SILENCY="$1"

    for RADIX in	    \
	/etc/bind	    \
	/etc/bind9	    \
	/var/lib/bind	    \
	/var/cache/bind	    \
	/var/run/named	    \
	/etc/default/bind9  \
	/etc/init.d/bind9
    do
	if [ -e "${RADIX}-${BINDTAG}" ]
	then
	    if [ "E$SILENCY" = "EDISPLAYALL" ]
	    then
		echo "there is already a ${RADIX}-${BINDTAG}"
	    else
		return 0
	    fi
	fi
    done
    return 1
}


if [ ! "${BINDTAG}" ]
then
    echo "missing instance name"
    usage
    exit 1
fi

if [ ! "${RNDCPORT}" ]
then
    echo "missing rndc port number"
    usage
    exit 1
fi

checkfordisttemplates "DISPLAYALL"
checkifpreviousexist "DISPLAYALL"

if checkifpreviousexist
then
    echo "ended with no file change"
    exit 1
fi
if checkfordisttemplates
then
    echo "ended with no file change"
    exit 1
fi

cp -a /etc/bind-dist "/etc/bind-${BINDTAG}"		    &&
cd /etc/bind-"${BINDTAG}"				    &&
rndc-confgen -a -c rndc.key				    &&
find /etc/bind-dist -type f | while read NOM
do
    SHORTNAME=`echo "$NOM" | rev | cut -d/ -f1 | rev`
    sed 's_/etc/bind_/etc/bind-'"${BINDTAG}"'_g' "${NOM}" |
    sed 's_/var/cache/bind_/var/cache/bind-'"${BINDTAG}"'_g' > \
    "/etc/bind-${BINDTAG}"/"${SHORTNAME}"
done							    &&
cp -a  "named.conf.local" "named.conf.local-noky"	    &&
sed 's/"rndc-key"/public/' rndc.key > named.conf.local	    &&
( sed 's_RNDCPORT_'"${RNDCPORT}"'_g' << 'CONTROLSTUB'
controls {
    inet 127.0.0.1 port RNDCPORT allow {localhost;} keys {"public";};
};
CONTROLSTUB
) >> named.conf.local					    &&
echo >> named.conf.local				    &&
cat "named.conf.local-noky" >> "named.conf.local"	    &&
( sed 's_RNDCPORT_'"${RNDCPORT}"'_g' << 'ENDOFRNDCCONF'
options {
  default-server  127.0.0.1;
  default-key     samplekey;
};
server 127.0.0.1 {
  port            RNDCPORT;
  key             public;
};
ENDOFRNDCCONF
sed 's/"rndc-key"/public/' rndc.key ) > rndc.conf	    &&
cp -a "named.conf.options" "named.conf.options-nopid"	    &&
sed 's_"options {_options {\npid-file "/var/run/named-'"${BINDTAG}"'/named.pid";\n_' \
    < "named.conf.options-nopid" > "named.conf.options"	    &&
mkdir		/var/run/named-${BINDTAG}		    &&
chown bind:bind /var/run/named-${BINDTAG}		    &&
chmod 775	/var/run/named-${BINDTAG}		    &&
mkdir		/var/cache/bind-${BINDTAG}		    &&
chown root:bind /var/cache/bind-${BINDTAG}		    &&
chmod 775	/var/cache/bind-${BINDTAG}		    &&
mkdir -p	/etc/bind-${BINDTAG}/slave		    &&
chown bind:bind /etc/bind-${BINDTAG}/slave		    &&
chmod 770	/etc/bind-${BINDTAG}/slave		    &&
mkdir -p	/etc/bind-${BINDTAG}/master		    &&
chown bind:bind /etc/bind-${BINDTAG}/master		    &&
chmod 770	/etc/bind-${BINDTAG}/master		    &&
( sed 's_INSTANCENAME_'"${BINDTAG}"'_g' << 'ENDOFETCDEFAULT'

# run resolvconf?
RESOLVCONF=no

# startup options for the server
OPTIONS="-u bind -c /etc/bind-INSTANCENAME/named.conf"

# rndc specialisation
RNDC_OPTIONS="-c /etc/bind-INSTANCENAME/rndc.conf"

ENDOFETCDEFAULT
) > "/etc/default/bind9-${BINDTAG}"			    &&
cat /etc/init.d/bind9      |
sed 's_^# Provides:.*$_# Provides: bind9-'"${BINDTAG}"'_'	|
sed 's_/etc/default/bind9_/etc/default/bind9-'"${BINDTAG}"'_g'	|
sed 's_/var/run/named_/var/run/named-'"${BINDTAG}"'_g'		|
sed 's_"bind9"_"bind9-'"${BINDTAG}"'"_g'			|
sed 's@/usr/sbin/rndc\s*stop@/usr/sbin/rndc \$RNDC_OPTIONS stop@g'  	|
sed 's@/usr/sbin/rndc\s*reload@/usr/sbin/rndc \$RNDC_OPTIONS reload@g'  	> \
"/etc/init.d/bind9-${BINDTAG}"				    &&
chmod 755 "/etc/init.d/bind9-${BINDTAG}"		    &&
ls -ld	"/etc/bind-${BINDTAG}"/*			    &&
ls -l	"/etc/default/bind9-${BINDTAG}" \
	"/etc/init.d/bind9-${BINDTAG}"			    &&
if [ -f /etc/apparmor.d/usr.sbin.named ]
then
 BAKSTAMP=`date "+%Y%m%d-%H%M"`				    &&
 cp -a /etc/apparmor.d/usr.sbin.named \
    /etc/apparmor/usr.sbin.named-orig-"${BAKSTAMP}"	    &&
 sed '/^}/q' /etc/apparmor/usr.sbin.named-orig-"${BAKSTAMP}" |
 grep -v '^}' > /etc/apparmor.d/usr.sbin.named		    &&
 ( cat << 'ENDOFAPPARMADD'
  # addition for instance bind9-INSTANCE
  /etc/bind-INSTANCE/** r,
  /var/lib/bind-INSTANCE/ rw,
  /var/lib/bind-INSTANCE/** rw,
  /var/cache/bind-INSTANCE/** rw,
  /var/cache/bind-INSTANCE/ rw,
  /{,var/}run/named-INSTANCE/named.pid w,
  /{,var/}run/named-INSTANCE/session.key w,
}
ENDOFAPPARMADD
) | sed 's/INSTANCE/'"${BINDTAG}"'/' \
  >> /etc/apparmor.d/usr.sbin.named			    &&
  echo							    &&
  echo apparmord additions '!!!' :			    &&
  echo diff /etc/apparmor/usr.sbin.named-orig-"${BAKSTAMP}" \
    /etc/apparmor.d/usr.sbin.named			    &&
  diff /etc/apparmor/usr.sbin.named-orig-"${BAKSTAMP}" \
    /etc/apparmor.d/usr.sbin.named			    
  echo							    &&
  echo apply with : service apparmor reload		    &&
  echo
fi							    &&
echo							    &&
echo "in order to activate bind9-${BINDTAG}, you may :"	    &&
echo "update-rc.d bind9-${BINDTAG} start 17 2 3 4 5 . stop 02 0 1 6"	&&
echo									&&
echo done


