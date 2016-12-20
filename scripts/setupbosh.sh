#!/bin/bash
#
# This script sets up the Jumpbox with Bosh. Run this script as *** root ***
#

set -e


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get -y update
apt-get install -y build-essential zlibc zlib1g-dev ruby2.0 ruby2.0-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
apt-get install libxslt1-dev libpq-dev libmysqlclient-dev zlib1g-dev
cd /usr/bin
rm ruby
ln -s ruby2.0 ruby
rm gem
ln -s gem2.0 gem
gem -v
wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.98-linux-amd64
mv bosh-init-0.0.98-linux-amd64 bosh-init
chmod a+x ./bosh-init
bosh-init
gem install bosh_cli --no-ri --no-rdoc
