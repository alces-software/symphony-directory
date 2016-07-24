#!/bin/bash

KEYTAB=/root/admin.keytab
KEYUSER=admin

CLUSTER=$1

if [ -z $CLUSTER ];
then
  echo "No cluster specified"
  echo "Usage: $0 <cluster name>"
  exit 1
fi

DIRECTORYAPPLIANCE=`hostname -f`
DOMAIN=`hostname -d`
REALM=$(echo $DOMAIN | sed -e 's/\(.*\)/\U\1/')

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa dnsrecord-del $REALM $CLUSTER --del-all
ipa dnszone-del $CLUSTER.$REALM

kdestroy
