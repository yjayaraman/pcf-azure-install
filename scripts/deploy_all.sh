#!/bin/bash
#
# 
#

set -e

# ------ PCF ------
 bosh -n deployment ~/manifests/deployments/cf.yml
 bosh -n deploy
 bosh -n run errand smoke-tests
 bosh -n run errand push-apps-manager
 bosh -n run errand notifications
 bosh -n run errand notifications-ui
 bosh -n run errand push-pivotal-account
 bosh -n run errand autoscaling
 bosh -n run errand autoscaling-register-broker

# ------ Metrics ------
 bosh -n upload stemcell ~/manifests/stemcells/bosh-stemcell-3233.2-azure-hyperv-ubuntu-trusty-go_agent.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/etcd-release-72.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/logsearch-release.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/metrix-1.1.0-beta.48.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/kafka-13.tgz --skip-if-exists
 bosh -n deployment ~/manifests/deployments/apm.yml
 bosh -n deploy
 bosh -n run errand push-apps

# ------ RabbitMQ ------
 bosh -n upload stemcell ~/manifests/stemcells/bosh-stemcell-3263.7-azure-hyperv-ubuntu-trusty-go_agent.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/cf-rabbitmq-222.6.0.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/service-metrics-1.4.3.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/loggregator-65.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/rabbitmq-metrics-1.29.0.tgz --skip-if-exists
 bosh -n deployment ~/manifests/deployments/p-rabbitmq.yml
 bosh -n deploy
 bosh -n run errand broker-registrar

# ------ MySQL ------
# -- No stem cell???
 bosh -n upload release ~/manifests/releases/cf-mysql-24.8.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/mysql-backup-1.27.3.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/service-backup-14.tgz --skip-if-exists
 bosh -n upload release ~/manifests/releases/mysql-monitoring-6.tgz --skip-if-exists
 bosh -n deployment ~/manifests/deployments/p-mysql.yml
 bosh -n deploy
 bosh -n run errand broker-registrar
 bosh -n run errand acceptance-tests


# ------ STS ------
 bosh -n upload release ~/manifests/releases/spring-cloud-broker-1.2.1-build.10.tgz --skip-if-exists
 bosh -n deployment ~/manifests/deployments/p-spring-cloud-services.yml
 bosh -n deploy
 bosh -n run errand register-service-broker
 bosh -n run errand run-smoke-tests