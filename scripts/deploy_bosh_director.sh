#!/bin/bash
#
# This script sets up the Jumpbox with Bosh. Run this script as *** root ***
#

set -e

cp temp/bosh*  ~/manifests/deployments/.
cd ~/manifests/deployments
bosh-init deploy ./bosh.yml
