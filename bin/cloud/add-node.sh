#!/bin/bash

KEYTAB=/root/admin.keytab
KEYUSER=admin

CLIENTNAME=$1
CLIENTIP=$2
CLUSTER=$3
ONETIMEPASS=$4
DOMAIN=$(hostname -d)
REALM=$(echo $DOMAIN | sed -e 's/\(.*\)/\U\1/')

function check_node {

    $DOMAINRECORDS=$(ipa dnsrecord-find $CLUSTER.$DOMAIN $CLIENTNAME |
                     grep "${CLIENTNAME}" |
                     awk '{print $3}')
    if [[ $DOMAINRECORDS == $CLIENTNAME || $REALMRECORDS == $CLIENTNAME ]];
    then
        echo "FAIL - ENTRY EXISTS"
        exit 0
    else
        add_node >> /dev/null
        echo "OK"
    fi

}

function add_node {

    ipa host-add $CLIENTNAME.$CLUSTER.$DOMAIN --ip-address=$CLIENTIP
    ipa host-mod $CLIENTNAME.$CLUSTER.$DOMAIN --password="${ONETIMEPASS}"
    ipa hostgroup-add-member usernodes --hosts $CLIENTNAME.$CLUSTER.$DOMAIN

}

if [[ -z $CLIENTNAME || -z $CLIENTIP || -z $CLUSTER || -z $ONETIMEPASS ]];
then
    echo "One or more variables not set"
    echo "Usage: $0 <client name> <client ip> <cluster> <one time password>"
    exit 0
else
    kinit -kt $KEYTAB $KEYUSER@$REALM
    check_node
    kdestroy
fi
