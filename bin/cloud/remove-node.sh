#!/bin/bash

CLIENTNAME=$1
CLUSTER=$2

KEYTAB=/root/hadder.keytab
KEYUSER=hadder
DOMAIN=$(hostname -d)
REALM=$(echo `hostname -d` | sed -e 's/\(.*\)/\U\1/')
REVERSEZONE="`hostname -i | cut -d . -f 3`.`hostname -i | cut -d . -f 2`.`hostname -i | cut -d . -f 1`.in-addr.arpa."

function check_node {

    DOMAINRECORDS=$(ipa dnsrecord-find $CLUSTER.$DOMAIN $CLIENTNAME |
                     grep "${CLIENTNAME}" |
                     awk '{print $3}')
    REALMRECORDS="login1"
    if [[ ! $DOMAINRECORDS == $CLIENTNAME || ! $REALMRECORDS == $CLIENTNAME ]];
    then
        echo "FAIL - NO ENTRY EXISTS"
        exit 0
    else
        remove_node >> /dev/null
        echo "OK"
    fi

}

function remove_node {

    ipa host-del $CLIENTNAME.$CLUSTER.$REALM --updatedns --continue

}

if [[ -z $CLIENTNAME || -z $CLUSTER ]];
then
    echo "One or more settings not provided"
    echo "Usage: $0 <client name> <cluster>"
    exit 0
else
    kinit -kt $KEYTAB $KEYUSER@$REALM
    check_node
    kdestroy
fi
