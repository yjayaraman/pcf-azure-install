#!/bin/bash
#
# this script is 'opinionated' and makes the following assumption
#
#   1.  everything will be created against the selected ("Default") Azure subscription
#   2.  current User has sufficient privileges to create AAD application and service principal
#   3.  Azure CLI is installed on the machine this script is run
#
#   This script will return clientID, tenantID, client-secret that can be used to
#   populate Azure marketplace offer of Pivotal cloud foundry.
set -e

spinner()
{
  spin[0]="-"
  spin[1]="\\"
  spin[2]="|"
  spin[3]="/"

  loop=1
  while [ $loop -le 100 ]
  do
    #Increment the loop
    loop=$((loop + 1))
    for i in "${spin[@]}"
    do
        echo -ne "\b\b\b\b\b\b\b\b$i $loop"
        sleep 0.1
    done
  done
}

error()
{
  echo -e "\033[1;31mERROR:\033[0m " $1 
}

echo_inputs()
{

  echo "*************************************************************************************"
  echo "*                                                                                   "
  echo "*   ENVIRONMENT        :    $ENVIRONMENT  "
  echo "*   SUBSCRIPTION_ID    :    $SUBSCRIPTIONID  "
  echo "*   tenantID           :    $TENANTID  "
  echo "*   clientID           :    $CLIENTID  "
  echo "*   CLIENTSECRET       :    $CLIENTSECRET  "
  echo "*   LOCATION           :    $LOCATION  "
  echo "*   RESOURCE_GROUP     :    $RESOURCE_GROUP  "
  echo "*                                                                                   "
  echo "*************************************************************************************"
#echo "{"
#echo "  \"\$schema\": \"http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#\","
#echo "  \"contentVersion\": \"1.0.0.0\","
#echo "  \"parameters\": {"
#echo "     \"SUBSCRIPTION_ID\": {"
#echo "       \"value\": \"$SUBSCRIPTIONID\""
#echo "    },"
#echo "     \"tenantID\": {"
#echo "       \"value\": \"$TENANTID\""
#echo "    },"
#echo "     \"clientID\": {"
#echo "       \"value\": \"$CLIENTID\""
#echo "    },"
#echo "     \"CLIENTSECRET\": {"
#echo "       \"value\": \"$CLIENTSECRET\""
#echo "    }"
#echo "  }"
#echo "}"

}
usage() 
{
  echo "$0 <azure subscription name>"
  echo '           This script creates a new Azure Service Principal under this subscription, '
  echo '           returning a clientID, tenantID, client-secret that can be used to'
  echo '           populate Azure marketplace offer of Pivotal Cloud Foundry.'
  echo
  echo '           e.g. "Pay-As-You-Go" is a common subscription name.  '
  echo
  echo '           Note that Azure Free Trials do not have sufficient'
  echo '           quota and are currently not supported.'
  echo	
}

if [ "$#" -ne 1 ]
then
  usage
  exit
fi
 

ENVIRONMENT="AzureUSGovernment"
echo "Environment Type: 1 - Azure, 2 - AzureUSGovernment"
read -p "Enter 1 or 2 (Press ENTER for 2):: " env
if [ -z $env ]; then
  env=2
fi
if [ $env -eq 1 ]; then
  ENVIRONMENT="Azure"
fi


# ensure ARM mode
#
azure config mode arm

azure account list --json

NAME=`azure account list | grep Enabled | grep true | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'`
SUBSCRIPTIONID=`azure account list | grep "$1" | grep true | awk -F '[[:space:]][[:space:]]+' '{ print $3 }'`

if [ -z $SUBSCRIPTIONID ]; then
  error "Subscription $1 not found."
  exit
fi

TENANTID=`azure account list --json | grep -A6 ${SUBSCRIPTIONID} | tail -1 | awk -F':' '{ print $2 }' | tr -d ',' | tr -d '"' `

# for multiple subscriptions, select the appropriate
#
azure account set $SUBSCRIPTIONID


read -p "Enter Service Principal App URI: (Press ENTER for http://pcfbosh): " IDURIS
if [ -z $IDURIS ]; then
   IDURIS="http://pcfbosh"
fi


PCFBOSHNAME=${IDURIS:7}
HOMEPAGE=$IDURIS
SPNAME=$IDURIS 


CLIENTID=`azure ad app show --identifierUri $IDURIS | grep ObjectId | awk -F':' '{print $3}' | tr -d ' '`

azure ad app delete $CLIENTID

read -p "Enter the location for the install: " LOCATION

if [ -z $LOCATION ]; then
   error "Invalid Location"
   exit
fi

read -p "Enter Resource Group: (THIS MUST BE CREATED PREVIOUSLY FROM AZURE PORTAL): " RESOURCE_GROUP
if [ -z $RESOURCE_GROUP ]; then
   error "Invalid Resource Group"
   exit
fi

read -p "Enter PCF Network Security Group Name: (Press ENTER for pcf-nsg): " PCF_NSG
if [ -z $PCF_NSG ]; then
   PCF_NSG="pcf-nsg"
fi

read -p "Enter PCF VNET Name: (Press ENTER for pcf-net): " PCF_NET
if [ -z $PCF_NET ]; then
   PCF_NET="pcf-net"
fi

read -p "Enter PCF SUBNET Name: (Press ENTER for pcf): " PCF_SUBNET
if [ -z $PCF_SUBNET ]; then
   PCF_SUBNET="pcf"
fi

read -p "Enter Storage Account Name: (Press ENTER for pcfsan): " STORAGE_NAME
if [ -z $STORAGE_NAME ]; then
   STORAGE_NAME="pcfsan"
fi

azure network nsg delete $RESOURCE_GROUP $PCF_NSG $LOCATION

azure network vnet subnet delete $RESOURCE_GROUP $PCF_NET $PCF_SUBNET

azure network vnet delete $RESOURCE_GROUP $PCF_NET  

azure storage account delete $STORAGE_NAME --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTIONID  

read -p "Enter Extra Storage Account Name: (Press ENTER for xtrapcfsan): " XTRA_STORAGE_NAME
if [ -z $XTRA_STORAGE_NAME ]; then
   XTRA_STORAGE_NAME="xtrapcfsan"
fi

loop=1
while [ $loop -le 3 ]
do
  azure storage account delete $XTRA_STORAGE_NAME$loop --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTIONID  

  #Increment the loop
  loop=$((loop + 1))

done

read -p "Enter LB Name: (Press ENTER for pcf-lb): " PCF_LB
if [ -z $PCF_LB ]; then
   PCF_LB="pcf-lb"
fi


azure network lb delete $RESOURCE_GROUP $PCF_LB $LOCATION

read -p "Enter Public IP Name: (Press ENTER for pcf-lb-ip): " PCF_LB_IP
if [ -z $PCF_LB_IP ]; then
   PCF_LB_IP="pcf-lb-ip"
fi

azure network public-ip delete $RESOURCE_GROUP $PCF_LB_IP $LOCATION

sleep 10

echo_inputs

spinner
