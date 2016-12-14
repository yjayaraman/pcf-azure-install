#!/bin/bash
#
# This script is 'opinionated' and makes the following assumption
#
#   1.  Azure CLI is installed on the machine this script is run
#   2.  Everything will be created against the selected ("Default") Azure subscription
#   3.  Current User has sufficient privileges to create AAD application and service principal
#     
#
#   On completion, this script will print the output parameters such as 
#   subscriptionID, clientID, tenantID, client-secret, and other details
#   that can be used to run Bosh init. The values are also saved in a file called 
#   create_azure_gov.txt

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
        echo -ne "\b\b\b\b\b\b\b\b\b\b\b$i We are done!!!!"
        sleep 0.1
    done
  done
}

echo_inputs()
{

  echo "*************************************************************************************"
  echo "*                                                                                   "
  echo "*   ENVIRONMENT        :    $ENVIRONMENT  "
  echo "*   SUBSCRIPTION_ID    :    $SUBSCRIPTIONID  "
  echo "*   TENANTID           :    $TENANTID  "
  echo "*   APP ID URI         :    $IDURIS "
  echo "*   HOMEPAGE           :    $HOMEPAGE  "
  echo "*   PCFBOSHNAME        :    $PCFBOSHNAME  "
  echo "*   CLIENTID           :    $CLIENTID  "
  echo "*   CLIENTSECRET       :    $CLIENTSECRET  "
  echo "*   RESOURCE_GROUP     :    $RESOURCE_GROUP  "
  echo "*   LOCATION           :    $LOCATION  "
  echo "*   PCF_NET            :    $PCF_NET  "
  echo "*   PCF_NSG            :    $PCF_NSG  "
  echo "*   STORAGE_NAME       :    $STORAGE_NAME  "
  echo "*   XTRA_STORAGE_NAME  :    $XTRA_STORAGE_NAME "
  echo "*   PCF_LB             :    $PCF_LB " 
  echo "*   PCF_LB_IP          :    $PCF_LB_IP " 
  echo "*   PUBLIC_IP          :    $PUBLIC_IP " 
  echo "*   PCF_FE_IP          :    $PCF_FE_IP " 
  echo "*                                                                                   "
  echo "*************************************************************************************"

  FILENAME="create_azure_gov.txt"
  # Opening file descriptors # 3 for reading and writing
  # i.e. /tmp/out.txt
  exec 3<>$FILENAME

  # Write to file
  echo "{" >&3
  echo "ENVIRONMENT        :    $ENVIRONMENT  " >&3
  echo "*   SUBSCRIPTION_ID    :    $SUBSCRIPTIONID  " >&3
  echo "*   TENANTID           :    $TENANTID  " >&3
  echo "*   APP ID URI         :    $IDURIS " >&3
  echo "*   HOMEPAGE           :    $HOMEPAGE  " >&3
  echo "*   PCFBOSHNAME        :    $PCFBOSHNAME  " >&3
  echo "*   CLIENTID           :    $CLIENTID  " >&3
  echo "*   CLIENTSECRET       :    $CLIENTSECRET  " >&3
  echo "*   RESOURCE_GROUP     :    $RESOURCE_GROUP  " >&3
  echo "*   LOCATION           :    $LOCATION  " >&3
  echo "*   PCF_NET            :    $PCF_NET  " >&3
  echo "*   PCF_NSG            :    $PCF_NSG  " >&3
  echo "*   STORAGE_NAME       :    $STORAGE_NAME  " >&3
  echo "*   XTRA_STORAGE_NAME  :    $XTRA_STORAGE_NAME " >&3
  echo "*   PCF_LB             :    $PCF_LB " >&3
  echo "*   PCF_LB_IP          :    $PCF_LB_IP " >&3
  echo "*   PUBLIC_IP          :    $PUBLIC_IP " >&3
  echo "*   PCF_FE_IP          :    $PCF_FE_IP " >&3
  echo "*                                                                                   " >&3
  echo "*************************************************************************************" >&3

  # close fd # 3
  exec 3>&-

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

create_service_principal() 
{
  echo "Creating AD Application and Service Principal ..."

  # client-secret		CLIENT-SECRET
  #
  CLIENTSECRET=`openssl rand -base64 16 | tr -dc _A-z-a-z-0-9`  

  # "application Id"	 CLIENT-ID
  #  

  CLIENTID=`azure ad app create --name "$PCFBOSHNAME" --password "$CLIENTSECRET" --identifier-uris ""$IDURIS"" --home-page ""$HOMEPAGE"" | grep  "AppId:" | awk -F':' '{ print $3 } ' | tr -d ' '`  
   

  sleep 10  

  azure ad sp create --applicationId $CLIENTID  

  sleep 10  

  azure role assignment create --roleName "Contributor"  --spn "$SPNAME" --subscription $SUBSCRIPTIONID

}

read_input()
{
	local inpt 
	read -p $1 inpt
	if [-z $inpt]; then
		return $2
	fi
	return inpt
}

error()
{
	echo -e "\033[1;31mERROR:\033[0m " $1 

	echo_inputs
}

create_networks()
{

   azure network nsg create $RESOURCE_GROUP $PCF_NSG $LOCATION   

   azure network nsg rule create $RESOURCE_GROUP $PCF_NSG internet-to-lb --protocol Tcp --priority 100 --destination-port-range '*'   

   azure network vnet create $RESOURCE_GROUP $PCF_NET $LOCATION --address-prefixes 10.0.0.0/16   

   azure network vnet subnet create $RESOURCE_GROUP $PCF_NET $PCF_SUBNET --address-prefix 10.0.0.0/20   

}

create_storage()
{
   azure storage account create $STORAGE_NAME --resource-group $RESOURCE_GROUP --sku-name LRS --kind Storage --subscription $SUBSCRIPTIONID  --location $LOCATION   

   CONNECTIONSTRING=`azure storage account connectionstring show $STORAGE_NAME  --resource-group $RESOURCE_GROUP | grep connectionstring: | cut -f3 -d':' | tr -d " "`   

   if [ -z $CONNECTIONSTRING ]; then
     error "Unable to get Connection String for Storage Account $STORAGE_NAME."
     exit
   fi   

   azure storage container create opsmanager --connection-string $CONNECTIONSTRING   

   azure storage container create bosh --connection-string $CONNECTIONSTRING   

   azure storage container create stemcell --permission blob --connection-string $CONNECTIONSTRING   

   azure storage table create stemcells --connection-string $CONNECTIONSTRING	
}

create_xtra_storage()
{
    loop=1
    while [ $loop -le 3 ]
    do
    	azure storage account create $XTRA_STORAGE_NAME$loop --resource-group $RESOURCE_GROUP --sku-name LRS --kind Storage --subscription $SUBSCRIPTIONID  --location $LOCATION    

    	CONNECTIONSTRING=`azure storage account connectionstring show $XTRA_STORAGE_NAME$loop  --resource-group $RESOURCE_GROUP | grep connectionstring: | cut -f3 -d':' | tr -d " "`    

    	if [ -z $CONNECTIONSTRING ]; then
    		error "Unable to get Connection String for Storage Account $XTRA_STORAGE_NAME$loop"
    		exit
    	fi    

    	azure storage container create bosh --connection-string $CONNECTIONSTRING    

    	azure storage container create stemcell --permission blob --connection-string $CONNECTIONSTRING    

        #Increment the loop
        loop=$((loop + 1))    

    done	
}

create_lb()
{
    azure network lb create $RESOURCE_GROUP $PCF_LB $LOCATION    

    azure network public-ip create $RESOURCE_GROUP $PCF_LB_IP $LOCATION --allocation-method Static    

    PUBLIC_IP=`azure network public-ip show yj-pcf-rg pcf-lb-ip | grep "IP Address" | cut -f3 -d":" | tr -d ' '`
    if [ -z $PUBLIC_IP ]; then
    	error "Unable to Public IP for $PCF_LB_IP"
    	exit
    fi    

    azure network lb frontend-ip create $RESOURCE_GROUP $PCF_LB $PCF_FE_IP --public-ip-name $PCF_LB_IP    

    azure network lb address-pool create $RESOURCE_GROUP $PCF_LB pcf-vms    

    azure network lb probe create $RESOURCE_GROUP $PCF_LB  tcp80 --protocol Tcp --port 80    

    azure network lb rule create $RESOURCE_GROUP $PCF_LB http --protocol tcp --frontend-port 80 --backend-port 80    

    azure network lb rule create $RESOURCE_GROUP $PCF_LB https --protocol tcp --frontend-port 443 --backend-port 443    

    azure network lb rule create $RESOURCE_GROUP $PCF_LB diego-ssh --protocol tcp --frontend-port 2222 --backend-port 2222

}

# Main Program 
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

# start with http://aka.ms/devicelogin
# will spin here until login completes
# disable login during testing --- 
azure login   --environment $ENVIRONMENT

# capture output for values
#
# "id"			SUBSCRIPTION-ID
# "tenandId"		TENANT-ID
#
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

create_service_principal

CLIENTID=`azure ad app show --identifierUri $IDURIS | grep  AppId | awk -F':' '{print $3}' | tr -d ' '`

if [ -z $CLIENTID ]; then
  error "Service Principal $IDURIS not found."
  exit
fi

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

create_networks

create_storage


read -p "Enter Extra Storage Account Name: (Press ENTER for xtrapcfsan): " XTRA_STORAGE_NAME
if [ -z $XTRA_STORAGE_NAME ]; then
   XTRA_STORAGE_NAME="xtrapcfsan"
fi

create_xtra_storage

read -p "Enter LB Name: (Press ENTER for pcf-lb): " PCF_LB
if [ -z $PCF_LB ]; then
   PCF_LB="pcf-lb"
fi

read -p "Enter Public IP Name: (Press ENTER for pcf-lb-ip): " PCF_LB_IP
if [ -z $PCF_LB_IP ]; then
   PCF_LB_IP="pcf-lb-ip"
fi

read -p "Enter LB Frontend IP Name: (Press ENTER for pcf-fe-ip): " PCF_FE_IP
if [ -z $PCF_FE_IP ]; then
   PCF_FE_IP="pcf-fe-ip"
fi

create_lb

echo_inputs

spinner





