#!/bin/bash

CLIENTNAME=login1
CLUSTER=cluster1
CLIENTIP=10.75.0.110
ONETIMEPASS=moose
KEYTAB=/root/hadder.keytab
KEYUSER=hadder

DOMAIN=`hostname -d`
REALM=`echo $DOMAIN | sed -e 's/\(.*\)/\U\1/'`

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa host-add $CLIENTNAME.$CLUSTER.$DOMAIN --ip-address=$CLIENTIP
ipa host-mod $CLIENTNAME.$CLUSTER.$DOMAIN --password "${ONETIMEPASS}"
ipa hostgroup-add-member usernodes --hosts $CLIENTNAME.$CLUSTER.$DOMAIN

kdestroy
