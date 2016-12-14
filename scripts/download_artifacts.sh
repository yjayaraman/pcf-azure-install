#!/bin/bash
#
# This script sets up the Downloads the artifacts required for bosh release.
#

set -e

cd ~
mkdir manifests

cd manifests

# Download Bosh YML
mkdir deployments
cd deployments
wget https://s3.amazonaws.com/azure-bosh/manifests/bosh.yml
wget https://s3.amazonaws.com/azure-bosh/deployments/cf-7b811c5be672876e98a0.yml
wget https://s3.amazonaws.com/azure-bosh/deployments/cloud_config.yml20161021-1756-1r6itgq

# Download Stemcells
cd ..
mkdir stemcells
cd stemcells
wget https://s3.amazonaws.com/azure-bosh/stemcells/bosh-stemcell-3233.2-azure-hyperv-ubuntu-trusty-go_agent.tgz
wget https://s3.amazonaws.com/azure-bosh/stemcells/bosh-stemcell-3262.21-azure-hyperv-ubuntu-trusty-go_agent.tgz
wget https://s3.amazonaws.com/azure-bosh/stemcells/bosh-stemcell-3263.4-azure-hyperv-ubuntu-trusty-go_agent.tgz
wget https://s3.amazonaws.com/azure-bosh/stemcells/bosh-stemcell-3263.7-azure-hyperv-ubuntu-trusty-go_agent.tgz

# Download Releases
cd ..
mkdir releases
cd releases
wget https://s3.amazonaws.com/azure-bosh/releases/cf-239.0.21-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/cf-autoscaling-36.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/cf-mysql-24.8.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/cf-mysql-26.6.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/cf-rabbitmq-222.6.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/cflinuxfs2-rootfs-1.33.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/consul-108.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/diego-0.1485.1-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/etcd-60.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/etcd-release-72.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/garden-linux-0.342.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/kafka-13.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/loggregator-65.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/logsearch-release.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/metrix-1.1.0-beta.48.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/mysql-backup-1.25.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/mysql-backup-1.27.3.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/mysql-monitoring-5.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/mysql-monitoring-6.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/notifications-24.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/notifications-ui-17.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/pivotal-account-1.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/push-apps-manager-release-652.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/rabbitmq-metrics-1.29.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/routing-0.138.4-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/service-backup-14.0.0-3262.19.0.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/service-backup-14.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/service-metrics-1.4.3.tgz
wget https://s3.amazonaws.com/azure-bosh/releases/spring-cloud-broker-1.2.1-build.10.tgz



