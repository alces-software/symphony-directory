#!/bin/bash -x

. /etc/symphony.cfg

PUPPET=1
IPA=1

YUMBASE=/opt/symphony/generic/etc/yum/centos7-base.conf

############# START PUPPET ###################
if [ $PUPPET -gt 0 ]; then
  yum -e 0 -y --config=$YUMBASE  --enablerepo epel --enablerepo puppet-base --enablerepo puppet-deps install puppet

cat << EOF > /etc/puppet/puppet.conf
[main]
vardir = /var/lib/puppet
logdir = /var/log/puppet
rundir = /var/run/puppet
ssldir = /var/lib/puppet/ssl
[agent]
pluginsync      = true
report          = false
ignoreschedules = true
daemon          = false
ca_server       = director
certname        = `hostname -s`
environment     = production
server          = director
EOF

  systemctl enable puppet

  echo "==========================================================================="
  echo "Please login to director and sign the certificate for this machine"
  echo "# puppet cert sign `hostname -s`"
  
  #Generate puppet signing request
  /usr/bin/puppet agent --test --waitforcert 10 --server director --environment symphony
  #second pass for luck
  /usr/bin/puppet agent --test --environment symphony
fi
############# END PUPPET #####################

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

  ipa-server-install -a "${ADMINPASSWORD}" --hostname directory.$DOMAIN --ip-address=10.78.254.2 -r "$REALM" -p "${ADMINPASSWORD}" -n "$DOMAIN" --no-ntp  --setup-dns --forwarder='10.78.254.1' --reverse-zone='10.in-addr.arpa.' --ssh-trust-dns --unattended 

  /opt/symphony/directory/bin/setup_domain.sh
fi
############# END PUPPET ###################
