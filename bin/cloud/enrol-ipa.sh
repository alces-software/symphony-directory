#!/bin/bash
CLIENTNAME=login1
CLUSTER=cluster2
CLIENTIP=10.75.0.51
ONETIMEPASS=moose

DOMAIN=flighty.alces.network
REALM=`echo $DOMAIN | sed -e 's/\(.*\)/\U\1/'`
DIRECTORY_IP=10.75.0.161

#STOP DHCP CHANGING RESOLV.CONF ON REBOOTS
sed -i -e "s/^PEERDNS.*$/PEERDNS=\"no\"/g" /etc/sysconfig/network-scripts/ifcfg-eth0
#PREP RESOLVE.CONF
echo -e "search $CLUSTER.$DOMAIN $DOMAIN\nnameserver $DIRECTORY_IP" > /etc/resolv.conf

yum -y install ipa-client ipa-admintools
echo ipa-client-install --no-ntp --mkhomedir --force-join --realm="$REALM" --server="${DIRECTORY_IP}" -w "$ONETIMEPASS" --domain="${CLUSTER}.${DOMAIN}" --unattended
