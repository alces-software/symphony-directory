#!/bin/bash

CLUSTER=cluster1
KEYTAB=/root/admin.keytab
KEYUSER=admin

DIRECTORYAPPLIANCE=`hostname -f`

DOMAIN=`hostname -d`
REALM=`echo $DOMAIN | sed -e 's/\(.*\)/\U\1/'`

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa dnszone-add $CLUSTER.$DOMAIN --name-server $DIRECTORYAPPLIANCE.
ipa dnsrecord-add $DOMAIN $CLUSTER --ns-rec=$DIRECTORYAPPLIANCE.

kdestroy
