#!/bin/bash
#
# This script sets up the Jumpbox with Bosh. Run this script as *** root ***
#

set -e

read -p "Enter the domain name you want to generate the SSL cert for:" DOMAIN_NAME

`sed s/__DOMAIN_NAME__/$DOMAIN_NAME/g <../templates/opensslconfig.cnf >temp/sslconfig.conf`

openssl genrsa -out temp/your-private-key.pem 2048

openssl req -sha256 -new -key temp/your-private-key.pem -out temp/csr.pem -config temp/sslconfig.conf

openssl x509 -req -days 3650 -in temp/csr.pem -signkey temp/your-private-key.pem -out temp/your-cert.pem -extensions v3_req -extfile temp/sslconfig.conf

openssl x509 -text -noout -in temp/your-cert.pem