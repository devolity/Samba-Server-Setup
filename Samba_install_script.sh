#!/usr/bash

# SAMBA Version 4.3.0 installer !!!

sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
iptables -F
yum clean all
yum clean metadata
#####################################

echo -e "|----------------------------------------------------------|"
echo -e "\x1b[32m"
echo -e " WELCOME SAMBA Version-4 installation With AD Environment " 
echo -e "\x1b[0m"
echo -e "|----------------------------------------------------------|"

echo -e "\x1b[32m"
read -p "Enter HostName = " hns
echo -e "\x1b[0m"

echo -e "\x1b[32m"
read -p "Enter Admin Password -Use Symbol,Upper&Lower,Digit = " aps
echo -e "\x1b[0m"

hostname "$hns"

echo -e "nameserver 127.0.0.1
domain $dnn
nameserver 8.8.8.8" > /etc/resolv.conf

#####################################

ips=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk '{print $2;}' | awk -F':' '{print $2;}'`
echo -e "$ips  $hns" >> /etc/hosts
sed -i "s/HOSTNAME=.*/HOSTNAME=$hns/g" /etc/sysconfig/network

#####################################

dnn=`echo $hns | cut -d"." -f2,3`
updn=`echo $dnn | tr '[:lower:]' '[:upper:]'`
dom=`hostname | cut -d"." -f2`
udom=`echo $dom | tr '[:lower:]' '[:upper:]'`

#####################################
#echo -e "You Really Want to Update Your System"
#yum update
#yum -y install gcc vim make wget perl python-devel gnutls-devel openssl-devel libacl-devel krb5-server pam_krb5 krb5-libs krb5-workstation bind bind-libs bind-utils openldap-devel ntp python*

yum -y install gcc make wget python-devel gnutls-devel openssl-devel libacl-devel krb5-server krb5-libs krb5-workstation bind bind-libs bind-utils perl openldap-devel

#####################################

rndc-confgen -a -r /dev/urandom
sed -i "s/listen-on port 53.*/listen-on port 53 { any; };/g" /etc/named.conf
sed -i "s/allow-query.*/allow-query { any; };/g" /etc/named.conf
echo -e 'include "/usr/local/samba/private/named.conf";' >> /etc/named.conf

#####################################

mkdir samba4
cd samba4

#####################################

wget https://dl.dropboxusercontent.com/u/17801313/Cloud/samba-latest.tar.gz
tar -xvf samba-latest.tar.gz
cd samba-*/
./configure --enable-selftest
make 
make install

#####################################

/usr/local/samba/bin/samba-tool domain provision --realm=$dnn --domain=$udom --adminpass $aps --server-role=dc --dns-backend=BIND9_DLZ

echo -e "[logging]
default = FILE:/var/log/krb5libs.log
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmind.log


[libdefaults]
default_realm = $updn
dns_lookup_realm = false
dns_lookup_kdc = true" > /etc/krb5.conf

#####################################

chown named:named /usr/local/samba/private/dns
chown named:named /usr/local/samba/private/dns.keytab
chmod 775 /usr/local/samba/private/dns

#####################################
touch /etc/init.d/samba4

echo -e '#! /bin/bash
#
# samba4 Bring up/down samba4 service
#
# chkconfig: - 90 10
# description: Activates/Deactivates all samba4 interfaces configured to
# start at boot time.
#
### BEGIN INIT INFO
# Provides:
# Should-Start:
# Short-Description: Bring up/down samba4
# Description: Bring up/down samba4
### END INIT INFO
# Source function library.
. /etc/init.d/functions
 
if [ -f /etc/sysconfig/samba4 ]; then
. /etc/sysconfig/samba4
fi
 
CWD=$(pwd)
prog="samba4"
 
start() {
# Attach irda device
echo -n $"Starting $prog: "
/usr/local/samba/sbin/samba
sleep 2
if ps ax | grep -v "grep" | grep -q /samba/sbin/samba ; then success $"samba4 startup"; else failure $"samba4 startup"; fi
echo
}
stop() {
# Stop service.
echo -n $"Shutting down $prog: "
killall samba
sleep 2
if ps ax | grep -v "grep" | grep -q /samba/sbin/samba ; then failure $"samba4 shutdown"; else success $"samba4 shutdown"; fi
echo
}
status() {
/usr/local/samba/sbin/samba --show-build
}
 
# See how we were called.
case "$1" in
start)
start
;;
stop)
stop
;;
status)
status irattach
;;
restart|reload)
stop
start
;;
*)
echo $"Usage: $0 {start|stop|restart|status}"
exit 1
esac
 
exit 0' > /etc/init.d/samba4

chmod 755 /etc/init.d/samba4

#####################################
/etc/init.d/ntpd start
/etc/init.d/named start
/etc/init.d/samba4 start

chkconfig --levels 235 samba4 on
chkconfig --levels 235 named on
chkconfig --levels 235 ntpd on

##################################### OUTPUT 
echo -e "++++++++++++++++++++++++++++++++++++"
echo -e "\x1b[32m"
echo -e "ToubleShooting Steps !!!"
echo -e "\x1b[0m"
echo -e "++++++++++++++++++++++++++++++++++++"

echo -e "1: Checking your Samba version it must be Version-4 or above"
echo -e "\x1b[32m"
/usr/local/samba/sbin/samba -V
echo -e "\x1b[0m"

echo -e "++++++++++++++++++++++++++++++++++++"
echo -e "2: Checking your Samba-Client version it must be Version-4 or above"
echo -e "\x1b[32m"
/usr/local/samba/bin/smbclient --version
echo -e "\x1b[0m"

echo -e "++++++++++++++++++++++++++++++++++++"
echo -e "3: Checking your Shares list Samba Server"
echo -e "\x1b[32m"
llogin=`/usr/local/samba/bin/smbclient -L  127.0.0.1 -U% ` 
echo $llogin
echo -e "\x1b[0m"

echo -e "++++++++++++++++++++++++++++++++++++"
echo -e "4: Checking Kerberose"
echo -e "\x1b[32m"
kinit administrator@$updn
echo -e "\x1b[0m"
#####################################