#!/bin/bash

KEYTAB=/root/admin.keytab
KEYUSER=admin

CLUSTER=$1
DIRECTORYAPPLIANCE=`hostname -f`
DOMAIN=`hostname -d`
REALM=$(echo $DOMAIN | sed -e 's/\(.*\)/\U\1/')

function check_cluster {
    if [ "$(ipa dnszone-find | grep "${CLUSTER}.${DOMAIN}." | awk '{print $3}')" == "${CLUSTER}.${DOMAIN}." ];
    then
        remove_cluster >> /dev/null
        echo "OK"
    else
        echo "CLUSTER ${CLUSTER} DOES NOT EXIST"
        exit 0
    fi
}

function remove_cluster {
    ipa dnsrecord-del $REALM $CLUSTER --del-all
    ipa dnszone-del $CLUSTER.$REALM
}

if [ -z $CLUSTER ];
then
    echo "No cluster specified"
    echo "Usage: $0 <cluster name>"
    exit 0
else
    kinit -kt $KEYTAB $KEYUSER@$REALM
    check_cluster
    kdestroy
fi
