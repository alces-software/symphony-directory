#!/bin/bash

NETWORKTYPE='FLAT'
CLUSTER=`hostname -d | cut -d '.' -f 1`
DOMAIN=`hostname -d`
REALM=`echo $DOMAIN | sed -e 's/\(.*\)/\U\1/'`
FORWARDER=`grep nameserver /etc/resolv.conf | awk '{print $2}'`
PASSWORD=Pa55W0rd

#PREP HOSTFILE
echo -ne "\n#localip entry\n`hostname -I`     `hostname -f` `hostname -s`"  >> /etc/hosts
sed -i '/127.0.0.1 directory/d' /etc/hosts
sed -i '/::1 directory/d' /etc/hosts
#STOP DHCP CHANGING RESOLV.CONF ON REBOOTS
sed -i -e "s/^PEERDNS.*$/PEERDNS=\"no\"/g" /etc/sysconfig/network-scripts/ifcfg-eth0

#This should work now we've sorted the host file
REVERSEZONE=`eval "dig +noall +answer -x \`hostname -i\` | cut -d ' ' -f 1 | cut -d. -f 2-"`

#INSTALL IPA
yum -y install ipa-server bind bind-dyndb-ldap ipa-server-dns
ipa-server-install -a "$PASSWORD" --hostname `hostname -f`  -r "$REALM" -p "$PASSWORD" -n "$DOMAIN" --no-ntp  --setup-dns --forwarder="$FORWARDER" --reverse-zone="$REVERSEZONE" --ssh-trust-dns --unattended

#Configure IPA
ipa-server-install -a "$PASSWORD" --hostname `hostname -f`  -r "$REALM" -p "$PASSWORD" -n "$DOMAIN" --no-ntp  --setup-dns --forwarder="$FORWARDER" --reverse-zone="$REVERSEZONE" --ssh-trust-dns --unattended

#Firewall Rules
sed -i '/#APPLIANCERULES#/a -A INPUT -i eth0 -p tcp -m multiport --dports 80,443,389,636,88,464,53 -j ACCEPT' /etc/sysconfig/iptables
sed -i '/#APPLIANCERULES#/a -A INPUT -i eth0 -p udp -m multiport --dports 88,464,53 -j ACCEPT' /etc/sysconfig/iptables

echo $PASSWORD | kinit admin
ipa config-mod --defaultshell /bin/bash
ipa config-mod --homedirectory /users
ipa group-add ClusterUsers --desc="Generic Cluster Users"
ipa group-add AdminUsers --desc="Admin Cluster Users"
ipa config-mod --defaultgroup ClusterUsers
ipa pwpolicy-mod --maxlife=999
ipa user-add flightuser --first Alces --last Flight --random
ipa group-add-member AdminUsers --users flightuser
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

ipa user-add --first=Host --last=Adder hadder
ipa privilege-add "Add computers" --desc "Add computers"
ipa privilege-add-permission "Add computers" --permissions="System: Add Hosts"
ipa privilege-add-permission "Add computers" --permissions="System: Add DNS Entries"
ipa privilege-add-permission "Add computers" --permissions="System: Read DNS Entries"
ipa privilege-add-permission "Add computers" --permissions="System: Modify Hosts"
ipa privilege-add-permission "Add computers" --permissions="System: Manage Host Enrollment Password"
ipa privilege-add-permission "Add computers" --permissions="System: Manage Host Keytab"
ipa privilege-add-permission "Add computers" --permissions="System: Modify Hostgroup Membership"
ipa privilege-add-permission "Add computers" --permissions="System: Remove Hosts"
ipa privilege-add-permission "Add computers" --permissions="System: Remove DNS Entries"
ipa privilege-add-permission "Add computers" --permissions="System: Update DNS Entries"

ipa role-add "Host Adder" --desc="Can add new hosts"
ipa role-add-privilege "Host Adder" --privilege="Add computers"
ipa role-add-member "Host Adder" --user=hadder

ipa-getkeytab -s `hostname` -p hadder@$REALM -k /root/hadder.keytab
ipa-getkeytab -s `hostname` -p admin@$REALM -k /root/admin.keytab
