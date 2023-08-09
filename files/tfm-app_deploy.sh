#!/bin/bash
#
# FOREMAN DEPLOY : FOREMAN APP (+local redis rails app cache)
#

wget https://apt.puppet.com/puppet6-release-buster.deb
dpkg -i puppet6-release-buster.deb
apt-get -qy update
apt --yes install puppet-agent

REQUIRED_PKG=foreman-installer
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
apt-get --yes install gnupg
wget -q https://deb.theforeman.org/pubkey.gpg -O- | apt-key add -
cat > /etc/apt/sources.list.d/foreman.list <<EOF
# Debian Buster
deb http://deb.theforeman.org/ buster 2.3
# Plugins compatible with Stable
deb http://deb.theforeman.org/ plugins 2.3
EOF
apt-get -qy update
apt-get --yes install $REQUIRED_PKG || exit 1
fi

apt-get --yes install puppet-agent
# trigger SSL signing after puppetserver deployment BUT before app deploy
/opt/puppetlabs/bin/puppet ssl bootstrap --server tfm-puppet.loxda.net

foreman-installer \
--skip-puppet-version-check \
--enable-foreman-plugin-memcache \
--foreman-plugin-memcache-hosts=['tfm-db.loxda.net'] \
--enable-foreman \
--no-enable-foreman-cli \
--no-enable-foreman-proxy \
--foreman-proxy-trusted-hosts={tfm-app.loxda.net,tfm-puppet.loxda.net} \
--enable-puppet \
--puppet-server=false \
--puppet-server-ca=false \
--foreman-db-manage=false \
--foreman-db-host=tfm-db.loxda.net \
--foreman-db-database=foreman \
--foreman-db-username=foreman \
--foreman-db-password=p4p1llon \
--enable-foreman-plugin-ansible \
--enable-foreman-plugin-remote-execution

puppet apply -e 'package { "ruby-foreman-templates": ensure => installed, } '
puppet apply -e 'package { "ruby-foreman-fog-proxmox": ensure => installed, } '
puppet apply -e 'package { "foreman-vmware": ensure => installed, } '

echo "oauth key: "
awk -F':' '$2 == "oauth_consumer_key" {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' /etc/foreman/settings.yaml
echo "oauth secret: "
awk -F':' '$2 == "oauth_consumer_secret" {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' /etc/foreman/settings.yaml

systemctl restart foreman.service
echo "to reset foreman admin password: foreman-rake permissions:reset"

