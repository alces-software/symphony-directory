#!/bin/bash -x

. /etc/symphony.cfg

SOURCE=1

YUMBASE=/opt/symphony/generic/etc/yum/centos7-base.conf

############# BEGIN SOURCE ###################
if [ $SOURCE -gt 0 ]; then
  mkdir /opt/symphony
  cd /opt/symphony
  git clone https://github.com/alces-software/symphony4.git generic
  git clone https://github.com/alces-software/symphony-director.git director
fi
############# END SOURCE ###################

#fix resolv.conf
  cat << EOF > /etc/resolv.conf
search bld.cluster.compute.estate prv.cluster.compute.estate mgt.cluster.compute.estate pub.cluster.compute.estate cluster.compute.estate
nameserver 10.78.254.1
EOF
