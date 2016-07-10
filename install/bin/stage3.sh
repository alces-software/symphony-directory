#!/bin/bash -x

. /etc/symphony.cfg

PUPPET=1

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

