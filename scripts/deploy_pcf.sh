#!/bin/bash
#
# This script sets up the Jumpbox with Bosh. Run this script as *** root ***
#

set -e



fatal()
{
  echo -e "\033[1;31mERROR:\033[0m " $1 
  exit
}


bosh -n  target 10.0.0.10

bosh login admin admin

BOSH_UUID=`bosh status | grep -w UUID |  awk -F '[[:space:]][[:space:]]+' '{ print $3}'`
if [ -z "$BOSH_UUID" ]; then
   fatal "Unable to login to BOSH director at 10.0.0.10"
fi

bosh -n update cloud_config.yml20161021-1756-1r6itgq


read -p "Enter the domain name you want to generate the SSL cert for:" DOMAIN_NAME

`sed s/__DOMAIN_NAME__/$DOMAIN_NAME/g <../templates/opensslconfig.cnf >temp/sslconfig.conf`

openssl genrsa -out temp/your-private-key.pem 2048

openssl req -sha256 -new -key temp/your-private-key.pem -out temp/csr.pem -config temp/sslconfig.conf

openssl x509 -req -days 3650 -in temp/csr.pem -signkey temp/your-private-key.pem -out temp/your-cert.pem -extensions v3_req -extfile temp/sslconfig.conf

openssl x509 -text -noout -in temp/your-cert.pem
