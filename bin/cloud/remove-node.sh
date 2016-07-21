#!/bin/bash

CLIENTNAME=$1
CLUSTER=$2

if [[ -z $CLIENTNAME || -z $CLUSTER ]];
then
    echo "Usage: $0 <client name> <cluster>"
    exit 1
fi

KEYTAB=/root/hadder.keytab
KEYUSER=hadder

DOMAIN=$(hostname -d | cut -d '.' -f 2-3)
REALM=$(echo `hostname -d` | sed -e 's/\(.*\)/\U\1/')

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa host-del $CLIENTNAME.$CLUSTER.$DOMAIN --updatedns --continue

kdestroy
