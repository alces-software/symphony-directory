#!/bin/bash

CLIENTNAME=`hostname -s`
CLUSTER=`hostname -d | cut -d . -f 1`
CLIENTIP=`hostname -i`
ONETIMEPASS=moose

DOMAIN=`hostname -d | cut -d . -f 2-3`
REALM=$(echo `hostname -d` | sed -e 's/\(.*\)/\U\1/')
DIRECTORY="directory.$CLUSTER.$DOMAIN"

#STOP DHCP CHANGING RESOLV.CONF ON REBOOTS
sed -i -e "s/^PEERDNS.*$/PEERDNS=\"no\"/g" /etc/sysconfig/network-scripts/ifcfg-eth0
#PREP RESOLVE.CONF
echo -e "search $CLUSTER.$DOMAIN $DOMAIN\nnameserver $DIRECTORY_IP" > /etc/resolv.conf

yum -y install ipa-client ipa-admintools
ipa-client-install --no-ntp --mkhomedir --force-join --realm="$REALM" --server="${DIRECTORY}" -w "$ONETIMEPASS" --domain="${CLUSTER}.${DOMAIN}" --unattended
