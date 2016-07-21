#!/bin/bash

KEYTAB=/root/admin.keytab
KEYUSER=admin

DIRECTORYAPPLIANCE=`hostname -f`

DOMAIN=`hostname -d | cut -d . -f 2-3`
REALM=`echo $DOMAIN | sed -e 's/\(.*\)/\U\1/'`

if [ ! -z $CLUSTER ];
then
    CLUSTER=$1
fi

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa dnszone-add $DOMAIN --name-server $DIRECTORYAPPLIANCE.
ipa dnsrecord-add $DOMAIN $CLUSTER --ns-rec=$DIRECTORYAPPLIANCE.

kdestroy
