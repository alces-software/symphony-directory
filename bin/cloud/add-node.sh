#!/bin/bash

CLIENTNAME=$1
CLIENTIP=$2
CLUSTER=$3
ONETIMEPASS=$4

if [[ -z $CLIENTNAME || -z $CLIENTIP || -z $CLUSTER || -z $ONETIMEPASS ]];
then
    echo "One or more variables not set"
    echo "Usage: $0 <client name> <client ip> <cluster> <one time password>"
    exit 1
fi

KEYTAB=/root/hadder.keytab
KEYUSER=hadder

DOMAIN=$(hostname -d)
REALM=$(echo $DOMAIN | sed -e 's/\(.*\)/\U\1/')

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa host-add $CLIENTNAME.$CLUSTER.$DOMAIN --ip-address=$CLIENTIP
ipa host-mod $CLIENTNAME.$CLUSTER.$DOMAIN --password "${ONETIMEPASS}"
ipa hostgroup-add-member usernodes --hosts $CLIENTNAME.$CLUSTER.$DOMAIN

kdestroy
