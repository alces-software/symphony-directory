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
        echo "FAILED"
        exit 1
    else
        add_cluster >> /dev/null
        echo "OK"
    fi
}

function add_cluster {
    ipa dnszone-add $CLUSTER.$DOMAIN --name-server $DIRECTORYAPPLIANCE.
    ipa dnsrecord-add $DOMAIN $CLUSTER --ns-rec=$DIRECTORYAPPLIANCE.
}

if [ -z $CLUSTER ];
then
    echo "No cluster specified"
    echo "Usage: $0 <cluster name>"
    exit 0
else
    kinit -kt $KEYTAB $KEYUSER
    check_cluster
    kdestroy
fi
