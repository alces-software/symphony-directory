#!/bin/bash

KEYTAB=/root/admin.keytab
KEYUSER=admin

DIRECTORYAPPLIANCE=`hostname -f`

CLUSTER=`hostname -d | cut -d . f 1`
DOMAIN=`hostname -d | cut -d . -f 2-3`
REALM=$(echo `hostname -d` | sed -e 's/\(.*\)/\U\1/')

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa dnszone-add $DOMAIN --name-server $DIRECTORYAPPLIANCE.
ipa dnsrecord-add $DOMAIN $CLUSTER --ns-rec=$DIRECTORYAPPLIANCE.

kdestroy
