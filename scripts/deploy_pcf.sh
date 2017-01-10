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


create_sed_commands()
{
 
  local FILENAME="temp/cf.txt"
  # Opening file descriptors # 3 for reading and writing
  # i.e. /tmp/out.txt
  exec 3<>$FILENAME

  # Write to file
  echo s/__DOMAIN_NAME__/$DOMAIN_NAME/g >&3
  echo s/__DIRECTOR_UUID__/$BOSH_UUID/g >&3


  # close fd # 3
  exec 3>&-
}

generate_cf_yml()
{
    create_sed_commands

    sed -f temp/cf.txt<temp/cf.tmp > temp/cf1.yml

    #PUB_CERT=$(<temp/your-cert.pem)
    PUB_CERT=`sed 's/^/       /' <temp/your-cert.pem`
    #PRI_KEY=$(<temp/your-private-key.pem)
    PRI_KEY=`sed 's/^/       /' <temp/your-private-key.pem`
    echo "Public cert is $PUB_CERT"
    awk -v var="$PUB_CERT" '{ sub(/__PUBLIC_CERT__/, var, $0) }1' temp/cf1.yml >temp/cf2.yml
    echo "Private key  is $PRI_KEY"
    awk -v var="$PRI_KEY" '{ sub(/__PRIVATE_KEY__/, var, $0) }1' temp/cf2.yml >~/manifests/deployments/cf.yml

}

generate_apm_yml()
{
    sed -f temp/cf.txt<../templates/apm.cnf > ~/manifests/deployments/apm.yml
}

generate_rabbitmq_yml()
{
    sed -f temp/cf.txt<../templates/p-rabbitmq.cnf > ~/manifests/deployments/p-rabbitmq.yml
}

generate_mysql_yml()
{
    sed -f temp/cf.txt<../templates/p-mysql.cnf > ~/manifests/deployments/p-mysql.yml
}

generate_spring_cloud_services_yml()
{
    sed -f temp/cf.txt<../templates/p-spring-cloud-services.cnf > ~/manifests/deployments/p-spring-cloud-services.yml
}

upload_artifacts()
{
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

}

# -------------------------------------------------------------------------------------------------------
# Main Program 
# -------------------------------------------------------------------------------------------------------

bosh -n  target 10.0.0.10

bosh login admin admin

BOSH_UUID=`bosh status | grep -w UUID |  awk -F '[[:space:]][[:space:]]+' '{ print $3}'`
if [ -z "$BOSH_UUID" ]; then
   fatal "Unable to login to BOSH director at 10.0.0.10"
fi

bosh -n update cloud-config temp/cloud_config.yml

read -p "Enter the domain name you want to generate the SSL cert for:" DOMAIN_NAME

`sed s/__DOMAIN_NAME__/$DOMAIN_NAME/g <../templates/opensslconfig.cnf >temp/sslconfig.conf`

openssl genrsa -out temp/your-private-key.pem 2048

openssl req -sha256 -new -key temp/your-private-key.pem -out temp/csr.pem -config temp/sslconfig.conf

openssl x509 -req -days 3650 -in temp/csr.pem -signkey temp/your-private-key.pem -out temp/your-cert.pem -extensions v3_req -extfile temp/sslconfig.conf

openssl x509 -text -noout -in temp/your-cert.pem

generate_cf_yml
generate_apm_yml
generate_rabbitmq_yml
generate_mysql_yml
generate_spring_cloud_services_yml

upload_artifacts

