#!/bin/bash -x

. /etc/symphony.cfg

IPA=1

############# START IPA ###################
if [ $IPA -gt 0 ]; then
  #PARENT DOMAIN TO BE MANAGED BY SYMPHONY
  DOMAIN=$CLUSTER.compute.estate

  BLDDOMAINHEADER=bld
  BLDDOMAIN=$BLDDOMAINHEADER.$DOMAIN

  #PRIMARY PRIVATE DOMAIN TO BE MANAGED BY SYMPHONY
  PRVDOMAINHEADER=prv
  PRVDOMAIN=$PRVDOMAINHEADER.$DOMAIN

  #Management domain to be managed by symphony (for bmc / switches etc)
  MGTDOMAINHEADER=mgt
  MGTDOMAIN=$MGTDOMAINHEADER.$DOMAIN

  #Public domain to be managed by symphony (for untrusted user facing network)
  PUBDOMAINHEADER=pub
  PUBDOMAIN=$PUBDOMAINHEADER.$DOMAIN

  #Extra domain to be managed by symphony (eg ib, stg)
  EXTRADOMAINHEADER=ib
  EXTRADOMAIN=$EXTRADOMAINHEADER.$DOMAIN

  REALM=`echo $DOMAIN | sed -e 's/\(.*\)/\U\1/'`

  echo $ADMINPASSWORD | kinit admin
  ipa dnszone-add $PRVDOMAIN --name-server directory.$DOMAIN.
  ipa dnszone-add $BLDDOMAIN --name-server directory.$DOMAIN.
  ipa dnsforwardzone-add $MGTDOMAIN. --forwarder 10.78.254.1 --forward-policy=only
  ipa dnsforwardzone-add $EXTRADOMAIN. --forwarder 10.78.254.1 --forward-policy=only
  ipa dnsforwardzone-add $PUBDOMAIN. --forwarder 10.78.254.1 --forward-policy=only
  ipa dnsrecord-add $DOMAIN. $PRVDOMAINHEADER --ns-rec=directory.$DOMAIN.
  ipa dnsrecord-add $DOMAIN. $BLDDOMAINHEADER --ns-rec=directory.$DOMAIN.
  ipa dnsrecord-add $DOMAIN director --a-ip-address=10.78.254.1
  ipa dnsrecord-add $BLDDOMAIN director --a-ip-address=10.78.254.1
  ipa dnsrecord-add $BLDDOMAIN repo --a-ip-address=10.78.254.3
  ipa dnsrecord-add $BLDDOMAIN monitor --a-ip-address=10.78.254.4

  ipa dnsrecord-add 10.in-addr.arpa. 1.254.78 --ptr-hostname director.$BLDDOMAIN.
  ipa dnsrecord-add 10.in-addr.arpa. 3.254.78 --ptr-hostname repo.$BLDDOMAIN.
  ipa dnsrecord-add 10.in-addr.arpa. 4.254.78 --ptr-hostname monitor.$BLDDOMAIN.

  ipa dnsrecord-add $DOMAIN. $EXTRADOMAINHEADER  --ns-rec=director
  ipa dnsrecord-add $DOMAIN. $MGTDOMAINHEADER --ns-rec=director
  ipa dnsrecord-add $DOMAIN. $PUBDOMAINHEADER --ns-rec=director
  ipa dnsrecord-add $DOMAIN. openstack --ns-rec=director
  ipa dnsrecord-add $PRVDOMAIN directory --a-ip-address=10.110.254.2
  ipa dnsrecord-add $BLDDOMAIN directory --a-ip-address=10.78.254.2

  ipa dnsrecord-add $DOMAIN @ --mx-preference=0 --mx-exchanger=director
  ipa dnsrecord-add $PRVDOMAINHEADER.$DOMAIN @ --mx-preference=0 --mx-exchanger=director
  ipa dnsrecord-add $BLDDOMAIN @ --mx-preference=0 --mx-exchanger=director

  ipa config-mod --defaultshell /bin/bash
  ipa config-mod --homedirectory /users
  ipa group-add ClusterUsers --desc="Generic Cluster Users"
  ipa group-add AdminUsers --desc="Admin Cluster Users"
  ipa config-mod --defaultgroup ClusterUsers
  ipa pwpolicy-mod --maxlife=999

  ipa user-add alces-cluster --first Alces --last Software --random
  ipa group-add-member AdminUsers --users alces-cluster

  ipa hbacrule-disable allow_all
  ipa hostgroup-add usernodes --desc "All nodes allowing standard user access"
  ipa hostgroup-add adminnodes --desc "All nodes allowing only admin user access"

  ipa hbacrule-add adminaccess --desc "Allow admin access to admin hosts"
  ipa hbacrule-add useraccess --desc "Allow user access to user hosts"
  ipa hbacrule-add-service adminaccess --hbacsvcs sshd
  ipa hbacrule-add-service useraccess --hbacsvcs sshd

  ipa hbacrule-add-user adminaccess --groups AdminUsers
  ipa hbacrule-add-user useraccess --groups ClusterUsers

  ipa hbacrule-add-host adminaccess --hostgroups adminnodes
  ipa hbacrule-add-host useraccess --hostgroups usernodes

  ipa sudorule-add --cmdcat=all All
  ipa sudorule-add-user --groups=adminusers All
  ipa sudorule-mod All --hostcat='all'
  ipa sudorule-add-option All --sudooption '!authenticate' 
fi
############# END IPA ###################
