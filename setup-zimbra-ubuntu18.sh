#!/bin/bash
clear

echo -e "##########################################################################"
echo -e "#               Ahmad Imanudin - https://www.imanudin.net                #"
echo -e "# If there any question about this script, feel free to contact me below #"
echo -e "#                    Contact at ahmad@imanudin.com                       #"
echo -e "##########################################################################"

echo ""
echo -e "Please make sure you have internet connection to install package"
echo ""
echo -e "Press key enter"
read presskey

echo -e "Preparing system ..........."
sleep 5
echo ""

# Update, upgrade and install dependencies
echo -e "[INFO] : Install dependencies"
sleep 3
apt-get update -y
apt-get upgrade -y
apt-get install -y bind9 bind9utils netcat-openbsd sudo libidn11 libpcre3 libgmp10 libexpat1 libstdc++6 libperl5.26 libaio1 resolvconf unzip pax sysstat sqlite3 net-tools
echo ""

# Disable services sendmail and postfix
echo -e "[INFO] : Disable service postfix and sendmail"
sleep 3
systemctl stop sendmail
systemctl stop postfix
systemctl disable sendmail
systemctl disable postfix
echo ""

# Configuring /etc/hosts, hostname and resolv.conf
echo -e "[INFO] : Configuring hostname, /etc/hosts and resolv.conf"
sleep 3

echo -n "Please insert your Hostname. Example mail : "
read HOSTNAME
echo -n "Please insert your Domain name. Example imanudin.net : "
read DOMAIN
echo -n "Please insert your IP Address : "
read IPADDRESS
echo ""

# /etc/hosts

cp /etc/hosts /etc/hosts.backup

echo "127.0.0.1       localhost" > /etc/hosts
echo "$IPADDRESS   $HOSTNAME.$DOMAIN       $HOSTNAME" >> /etc/hosts
host -t A keyserver.ubuntu.com | awk '{print $4,$1}' >> /etc/hosts

# Change Hostname
hostnamectl set-hostname $HOSTNAME.$DOMAIN

# /etc/resolv.conf
cp /etc/resolvconf/resolv.conf.d/head /etc/resolvconf/resolv.conf.d/head.backup

echo "search $DOMAIN" > /etc/resolvconf/resolv.conf.d/head
echo "nameserver $IPADDRESS" >> /etc/resolvconf/resolv.conf.d/head
echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/head
echo "nameserver 1.1.1.1" >> /etc/resolvconf/resolv.conf.d/head

systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl enable resolvconf
systemctl restart resolvconf

# Configuring DNS Server
echo ""
echo -e "[INFO] : Configuring DNS Server"
sleep 3

BIND=`ls /etc/bind/ | grep named.conf.local.back`;

        if [ "$BIND" == "named.conf.local.back" ]; then
	cp /etc/bind/named.conf.local.back /etc/bind/named.conf.local       
        else
	cp /etc/bind/named.conf.local /etc/bind/named.conf.local.back        
        fi


echo 'zone "'$DOMAIN'" IN {' >> /etc/bind/named.conf.local
echo "type master;" >> /etc/bind/named.conf.local
echo 'file "/etc/bind/'db.$DOMAIN'";' >> /etc/bind/named.conf.local
echo "};" >> /etc/bind/named.conf.local

touch /etc/bind/db.$DOMAIN
chgrp bind /etc/bind/db.$DOMAIN


echo '$TTL 1D' > /etc/bind/db.$DOMAIN
echo "@       IN SOA  ns1.$DOMAIN. root.$DOMAIN. (" >> /etc/bind/db.$DOMAIN
echo '                                        0       ; serial' >> /etc/bind/db.$DOMAIN
echo '                                        1D      ; refresh' >> /etc/bind/db.$DOMAIN
echo '                                        1H      ; retry' >> /etc/bind/db.$DOMAIN
echo '                                        1W      ; expire' >> /etc/bind/db.$DOMAIN
echo '                                        3H )    ; minimum' >> /etc/bind/db.$DOMAIN
echo "@		IN	NS	ns1.$DOMAIN." >> /etc/bind/db.$DOMAIN
echo "@		IN	MX	0 $HOSTNAME.$DOMAIN." >> /etc/bind/db.$DOMAIN
echo "ns1	IN	A	$IPADDRESS" >> /etc/bind/db.$DOMAIN
echo "$HOSTNAME	IN	A	$IPADDRESS" >> /etc/bind/db.$DOMAIN

# Restart Service & Check results configuring DNS Server

systemctl enable bind9
systemctl restart bind9
nslookup $HOSTNAME.$DOMAIN
dig $DOMAIN mx

echo ""
echo "Configuring /etc/hosts, hostname, /etc/resolve.con and DNS server has been finished. please install Zimbra now"
