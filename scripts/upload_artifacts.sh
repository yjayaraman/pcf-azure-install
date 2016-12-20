#!/bin/bash
#
# This script uploads the artifacts required for bosh release.
#

set -e

cd ~
cd manifests
bosh -n upload stemcell stemcells/bosh-stemcell-3262.21-azure-hyperv-ubuntu-trusty-go_agent.tgz --skip-if-exists

bosh -n upload release releases/push-apps-manager-release-652.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/cf-autoscaling-36.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/cf-mysql-26.6.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/cf-239.0.21-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/cflinuxfs2-rootfs-1.33.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/consul-108.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/diego-0.1485.1-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/etcd-60.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/garden-linux-0.342.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/mysql-backup-1.25.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/mysql-monitoring-5.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/notifications-24.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/notifications-ui-17.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/pivotal-account-1.0.0-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/routing-0.138.4-3262.19.0.tgz --skip-if-exists

bosh -n upload release releases/service-backup-14.0.0-3262.19.0.tgz --skip-if-exists
