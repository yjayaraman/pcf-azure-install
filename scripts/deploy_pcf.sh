#!/bin/bash
#
# This script sets up the Jumpbox with Bosh. Run this script as *** root ***
#

set -e

read -p "Enter the domain name you want to generate the SSL cert for:" DOMAIN_NAME

`sed s/__DOMAIN_NAME__/$DOMAIN_NAME/g <../templates/opensslconfig.cnf >openssl.cnf`

openssl genrsa -out your-private-key.pem 2048

openssl req -sha256 -new -key your-private-key.pem -out csr.pem -config openssl.cnf

openssl x509 -req -days 3650 -in csr.pem -signkey your-private-key.pem -out your-cert.pem -extensions v3_req -extfile openssl.cnf

openssl x509 -text -noout -in your-cert.pem
