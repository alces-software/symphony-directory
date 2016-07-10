#!/bin/bash -x

. /etc/symphony.cfg

SOURCE=1
IPA=1

YUMBASE=/opt/symphony/generic/etc/yum/centos7-base.conf

############# BEGIN SOURCE ###################
if [ $SOURCE -gt 0 ]; then
  mkdir /opt/symphony
  cd /opt/symphony
  git clone https://github.com/alces-software/symphony4.git generic
  git clone https://github.com/alces-software/symphony-directory.git directory
fi
############# END SOURCE ###################

############# BEGIN IPA ###################
if [ $IPA -gt 0 ]; then
  yum --config=$YUMBASE -y install ipa-server bind bind-dyndb-ldap ipa-server-dns
  firewall-cmd --add-service ssh --zone prv --permanent
  firewall-cmd --add-service ssh --zone bld --permanent
  firewall-cmd --add-service http --zone prv --permanent
  firewall-cmd --add-service https --zone prv --permanent
  firewall-cmd --add-service ldap --zone prv --permanent
  firewall-cmd --add-service ldaps --zone prv --permanent
  firewall-cmd --add-service kerberos --zone prv --permanent
  firewall-cmd --add-service kpasswd --zone prv --permanent
  firewall-cmd --add-service dns --zone prv --permanent
  firewall-cmd --add-service http --zone bld --permanent
  firewall-cmd --add-service https --zone bld --permanent
  firewall-cmd --add-service ldap --zone bld --permanent
  firewall-cmd --add-service ldaps --zone bld --permanent
  firewall-cmd --add-service kerberos --zone bld --permanent
  firewall-cmd --add-service kpasswd --zone bld --permanent
  firewall-cmd --add-service dns --zone bld --permanent
  firewall-cmd --reload
fi
############# END IPA ###################

#fix resolv.conf
  cat << EOF > /etc/resolv.conf
search bld.cluster.compute.estate prv.cluster.compute.estate mgt.cluster.compute.estate pub.cluster.compute.estate cluster.compute.estate
nameserver 10.78.254.1
EOF
