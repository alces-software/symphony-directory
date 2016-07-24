#!/bin/bash
set -ex
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
REVERSEZONE="`hostname -i | cut -d . -f 3`.`hostname -i | cut -d . -f 2`.`hostname -i | cut -d . -f 1`.in-addr.arpa."

kinit -kt $KEYTAB $KEYUSER@$REALM

ipa host-del $CLIENTNAME.$CLUSTER.$REALM --updatedns --continue
ipa dnsrecord-del $CLUSTER.$REALM $CLIENTNAME --del-all

# Work out the record number for client 
RECORDNUMBER=$(ipa dnsrecord-find 0.75.10.in-addr.arpa. | grep -B 1 "$CLIENTNAME.$CLUSTER.$REALM" | grep "Record name:" | awk '{print $3}')
ipa dnsrecord-del $REVERSEZONE $RECORDNUMBER --del-all

kdestroy
