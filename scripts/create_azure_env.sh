#!/bin/bash
#
# This script is 'opinionated' and makes the following assumption
#
#   1.  Azure CLI is installed on the machine this script is run
#   2.  You need to have a valid SubscriptionID and a ResourceGroup created in the location of choice"
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
  while [ $loop -le 100 ];
  do
    #Increment the loop
    loop=$((loop + 1))
    for i in "${spin[@]}"
    do
        echo -ne "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b$i We are done!!!!"
        sleep 0.1
    done
  done
}

yesno()
{
  local Y_N
  while [ -z $Y_N ]
  do
      read -p "Do you want to continue? [y/n] " Y_N

      case "$Y_N" in
              y)
                  return
                  ;;
               
              n)
                  exit
                  ;;
               
              *)
                  Y_N=""
       
      esac
  done
}

echo_tofile()
{

  FILENAME="create_azure_gov.txt"
  # Opening file descriptors # 3 for reading and writing
  # i.e. /tmp/out.txt
  exec 3<>$FILENAME

  # Write to file
  echo "ENVIRONMENT=$ENVIRONMENT  " >&3
  echo "SUBSCRIPTION_ID=$SUBSCRIPTIONID  " >&3
  echo "TENANTID=$TENANTID  " >&3
  echo "APP ID URI =$IDURIS " >&3
  echo "HOMEPAGE=$HOMEPAGE  " >&3
  echo "PCFBOSHNAME=$PCFBOSHNAME  " >&3
  echo "CLIENTID=$CLIENTID  " >&3
  echo "CLIENTSECRET=$CLIENTSECRET  " >&3
  echo "RESOURCE_GROUP=$RESOURCE_GROUP  " >&3
  echo "LOCATION=$LOCATION  " >&3
  echo "PCF_NET=$PCF_NET  " >&3
  echo "PCF_NSG=$PCF_NSG  " >&3
  echo "STORAGE_NAME=$STORAGE_NAME  " >&3
  echo "XTRA_STORAGE_NAME=$XTRA_STORAGE_NAME " >&3
  echo "PCF_LB=$PCF_LB " >&3
  echo "PCF_LB_IP=$PCF_LB_IP " >&3
  echo "PUBLIC_IP=$PUBLIC_IP " >&3
  echo "PCF_FE_IP=$PCF_FE_IP " >&3
  echo "PCF_SSH_LB_IP=$PCF_SSH_LB_IP " >&3
  echo "PUBLIC_SSH_IP=$PUBLIC_SSH_IP " >&3
  echo "PCF_SSH_FE_IP=$PCF_SSH_FE_IP " >&3


  # close fd # 3
  exec 3>&-
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
  echo "*   PCF_SSH_LB_IP      :    $PCF_SSH_LB_IP " 
  echo "*   PUBLIC_SSH_IP      :    $PUBLIC_SSH_IP " 
  echo "*   PCF_SSH_FE_IP      :    $PCF_SSH_FE_IP "                                                                                    
  echo "*************************************************************************************"

}

usage() 
{
  echo
  echo -e " #This script is 'opinionated' and makes the following assumptions:"
  echo 
  echo -e "\033[1;92m #   1.  Azure CLI is installed on this machine \033[0m"
  echo -e "\033[1;92m #   2.  You need to have a valid 'SubscriptionID' \033[0m"
  echo -e "\033[1;92m #   3.  You need to have a valid 'ResourceGroup' created in the 'Location' of choice  \033[0m"
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
   

  azure ad sp create --applicationId $CLIENTID  
 

  azure role assignment create --roleName "Contributor"  --spn "$SPNAME" --subscription $SUBSCRIPTIONID

}

read_subscription_id()
{
  while [ -z $SUBSCRIPTIONID ]; do
      echo
      azure account list | grep -w "Enabled" | grep -w "true" | awk -F '[[:space:]][[:space:]]+' '{ print $3 }'
      echo 
      read -p "Enter SUBSCRIPTIONID from the list above : " SUBSCRIPTIONID
      if [ -n "$SUBSCRIPTIONID" ]; then
        SUBSCRIPTIONID=`azure account list | grep -w $SUBSCRIPTIONID | grep -w "Enabled" | grep -w "true" | awk -F '[[:space:]][[:space:]]+' '{ print $3 }'  `
      fi
  done
}

read_location() 
{
    while [ -z $LOCATION ]; do
      echo
      azure location list | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'
      echo
      read -p "Enter the location from the list above: " LOCATION 
      if [ -n "$LOCATION" ]; then
        LOCATION=`azure location list | grep -w " $LOCATION " | awk -F '[[:space:]][[:space:]]+' '{ print $2 }' ` 
        echo -e "Using location: $LOCATION" 
      fi

    done 
}
read_resource_group()
{
    while [ -z $RESOURCE_GROUP ]; do
      echo
      azure group list | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'
      echo
      read -p "Enter the Resource Group from the list above: " RESOURCE_GROUP 
      if [ -n "$RESOURCE_GROUP" ]; then
        RESOURCE_GROUP=`azure group list | grep -w " $RESOURCE_GROUP " | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'  `
        echo -e "Using resource group: $RESOURCE_GROUP"
      fi
    done
}
read_nsg()
{
    while [ -z $RESOURCE_GROUP ]; do
      echo
      azure group list | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'
      echo
      read -p "Enter the Resource Group from the list above: " RESOURCE_GROUP 
      if [ -n "$RESOURCE_GROUP" ]; then
        RESOURCE_GROUP=`azure group list | grep -w " $RESOURCE_GROUP " | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'  `
        echo -e "Using resource group: $RESOURCE_GROUP"
      fi
    done
}

read_service_principal()
{
    while [ -z $CLIENTID ]; do
      read -p "Enter Service Principal App URI: (Press ENTER for http://pcfbosh): " IDURIS
      if [ -z $IDURIS ]; then
          IDURIS="http://pcfbosh"
      fi  
      PCFBOSHNAME=${IDURIS:7}
      HOMEPAGE=$IDURIS
      SPNAME=$IDURIS 
      CLIENTID=`azure ad app show --identifierUri $IDURIS | grep  -w AppId | awk -F':' '{print $3}' | tr -d ' '`
      if [ -n "$CLIENTID" ]; then
         echo
         echo " Service Principal exists for $IDURIS "
         yesno
         CLIENTSECRET="2c0pmtWhUMlPvykMiwep5Q"
      else
        create_service_principal
      fi       
      local TEMPSTR=`azure login --username  $CLIENTID  --password $CLIENTSECRET --service-principal --tenant $TENANTID —environment $ENVIRONMENT | grep "login command OK" `
      if [ -z "$TEMPSTR" ]; then
          error "Unable to login using --username  $CLIENTID  --password $CLIENTSECRET --service-principal --tenant $TENANTID —environment $ENVIRONMENT "
          CLIENTID=""
      fi

    done
}

read_nsg()
{
  read -p "Enter PCF Network Security Group Name: (Press ENTER for pcf-nsg): " PCF_NSG
  if [ -z $PCF_NSG ]; then
       PCF_NSG="pcf-nsg"
  fi
  local z=$PCF_NSG
  PCF_NSG=`azure network nsg list | grep -w $PCF_NSG |  grep -w $LOCATION | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'`
  if [ -n "$PCF_NSG" ]; then
      echo
      echo -e "NSG exists for $PCF_NSG"
      yesno
  else
    PCF_NSG=$z
    create_nsg
  fi

}

read_vnet()
{
  read -p "Enter PCF VNET Name: (Press ENTER for pcf-net): " PCF_NET
  if [ -z $PCF_NET ]; then
      PCF_NET="pcf-net"
  fi 
  local z=$PCF_NET
  PCF_NET=`azure network vnet list | grep -w $PCF_NET |  grep -w $LOCATION | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'`
  if [ -n "$PCF_NET" ]; then
      echo
      echo -e "VNET exists for $PCF_NET"
      yesno
  else
    PCF_NET=$z
    create_vnet
  fi
}


read_storage()
{
  read -p "Enter Storage Account Name: (Press ENTER for pcfsan): " STORAGE_NAME
  if [ -z $STORAGE_NAME ]; then
      STORAGE_NAME="pcfsan"
  fi

  CONNECTIONSTRING=`azure storage account connectionstring show $STORAGE_NAME  --resource-group $RESOURCE_GROUP | grep connectionstring: | cut -f3 -d':' | tr -d " "`   

  if [ -n "$CONNECTIONSTRING" ]; then
      echo
      echo "Storage exists for $STORAGE_NAME"
      yesno
  else
    create_storage
  fi
}

read_xtrastorage()
{
    read -p "Enter Extra Storage Account Name: (Press ENTER for xtrapcfsan): " XTRA_STORAGE_NAME
    if [ -z $XTRA_STORAGE_NAME ]; then
       XTRA_STORAGE_NAME="xtrapcfsan"
    fi 

    local loop=1
    while [ $loop -le 3 ]
    do
      CONNECTIONSTRING=`azure storage account connectionstring show $XTRA_STORAGE_NAME$loop  --resource-group $RESOURCE_GROUP | grep connectionstring: | cut -f3 -d':' | tr -d " "`  
      if [ -n "$CONNECTIONSTRING" ]; then
        echo
        echo -e "Storage exists for $XTRA_STORAGE_NAME$loop"
        yesno
      else
       create_storage
      fi 
      #Increment the loop
      loop=$((loop + 1)) 
    done


}


read_lb()
{
    read -p "Enter LB Name: (Press ENTER for pcf-lb): " PCF_LB
    if [ -z $PCF_LB ]; then
       PCF_LB="pcf-lb"
    fi    

 
  local z=$PCF_LB
  PCF_LB=`azure network lb list  $RESOURCE_GROUP | grep -w $PCF_LB | awk -F '[[:space:]][[:space:]]+' '{ print $2}'`
  if [ -n "$PCF_LB" ]; then
      echo
      echo "Load Balancer exists for $PCF_LB"
      yesno
  else
    PCF_LB=$z
    create_lb
  fi
}


read_ssh_lb()
{
    read -p "Enter SSH LB Name: (Press ENTER for pcf-ss-lb): " PCF_SSH_LB
    if [ -z $PCF_SSH_LB ]; then
       PCF_SSH_LB="pcf-ssh-lb"
    fi    

 
  local z=$PCF_SSH_LB
  PCF_SSH_LB=`azure network lb list  $RESOURCE_GROUP | grep -w $PCF_SSH_LB | awk -F '[[:space:]][[:space:]]+' '{ print $2}'`
  if [ -n "$PCF_SSH_LB" ]; then
      echo
      echo "Load Balancer exists for $PCF_SSH_LB"
      yesno
  else
    PCF_SSH_LB=$z
    create_ssh_lb
  fi
}

read_inputs_create_resources()
{

    read_location
    echo -e "\033[1;34m Using location: $LOCATION \033[0m"

    read_resource_group
    echo -e "\033[1;34m Using ResourceGroup: $RESOURCE_GROUP \033[0m"

    read_service_principal  
    echo -e "\033[1;34m Using ResourceGroup: $RESOURCE_GROUP \033[0m"

    read_nsg  
    echo -e "\033[1;34m Using NSG: $PCF_NSG \033[0m"
   
    read_vnet
    echo -e "\033[1;34m Using VNET: $PCF_NET \033[0m"
    echo -e "\033[1;34m Using SUBNET: $PCF_SUBNET \033[0m"

    read_storage
    echo -e "\033[1;34m Using Storage: $STORAGE_NAME \033[0m"
    
    read_xtrastorage
    echo -e "\033[1;34m Using Extra Storage: $XTRA_STORAGE_NAME \033[0m"

    read_lb
    echo -e "\033[1;34m Using LB: $PCF_LB \033[0m"

    read_ssh_lb
    echo -e "\033[1;34m Using SSH LB: $PCF_SSH_LB \033[0m"

}

error()
{
  echo -e "\033[1;31mERROR:\033[0m " $1 
}

fatal()
{
  echo -e "\033[1;31mERROR:\033[0m " $1 

  echo_inputs
  exit
}

create_nsg() 
{
    azure network nsg create $RESOURCE_GROUP $PCF_NSG $LOCATION 
    azure network nsg rule create $RESOURCE_GROUP $PCF_NSG internet-to-lb --protocol Tcp --priority 100 --destination-port-range '*'   
}

create_vnet()
{
  read -p "Enter PCF SUBNET Name: (Press ENTER for pcf): " PCF_SUBNET
  if [ -z $PCF_SUBNET ]; then
     PCF_SUBNET="pcf"
  fi 

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
    local loop=1
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

    read -p "Enter Public IP Name: (Press ENTER for pcf-lb-ip): " PCF_LB_IP
    if [ -z $PCF_LB_IP ]; then
       PCF_LB_IP="pcf-lb-ip"
    fi    

    read -p "Enter LB Frontend IP Name: (Press ENTER for pcf-fe-ip): " PCF_FE_IP
    if [ -z $PCF_FE_IP ]; then
       PCF_FE_IP="pcf-fe-ip"
    fi

    azure network public-ip create $RESOURCE_GROUP $PCF_LB_IP $LOCATION --allocation-method Static    

    PUBLIC_IP=`azure network public-ip show $RESOURCE_GROUP $PCF_LB_IP | grep "IP Address" | cut -f3 -d":" | tr -d ' '`
    if [ -z $PUBLIC_IP ]; then
    	error "Unable to Public IP for $PCF_LB_IP"
    	exit
    fi    

    azure network lb frontend-ip create $RESOURCE_GROUP $PCF_LB $PCF_FE_IP --public-ip-name $PCF_LB_IP    

    azure network lb address-pool create $RESOURCE_GROUP $PCF_LB pcf-vms    

    azure network lb probe create $RESOURCE_GROUP $PCF_LB  tcp80 --protocol Tcp --port 80    

    azure network lb rule create $RESOURCE_GROUP $PCF_LB http --protocol tcp --frontend-port 80 --backend-port 80    

    azure network lb rule create $RESOURCE_GROUP $PCF_LB https --protocol tcp --frontend-port 443 --backend-port 443    

}

create_ssh_lb()
{
    azure network lb create $RESOURCE_GROUP $PCF_SSH_LB $LOCATION    

    read -p "Enter Public IP Name: (Press ENTER for pcf-ssh-lb-ip): " PCF_SSH_LB_IP
    if [ -z $PCF_SSH_LB_IP ]; then
       PCF_SSH_LB_IP="pcf-ssh-lb-ip"
    fi    

    read -p "Enter LB Frontend IP Name: (Press ENTER for pcf-ssh-fe-ip): " PCF_SSH_FE_IP
    if [ -z $PCF_SSH_FE_IP ]; then
       PCF_SSH_FE_IP="pcf-ssh-fe-ip"
    fi

    azure network public-ip create $RESOURCE_GROUP $PCF_SSH_LB_IP $LOCATION --allocation-method Static    

    PUBLIC_SSH_IP=`azure network public-ip show $RESOURCE_GROUP $PCF_SSH_LB_IP | grep "IP Address" | cut -f3 -d":" | tr -d ' '`
    if [ -z $PUBLIC_SSH_IP ]; then
      error "Unable to Public IP for $PCF_SSH_LB_IP"
      exit
    fi    

    azure network lb frontend-ip create $RESOURCE_GROUP $PCF_SSH_LB $PCF_SSH_FE_IP --public-ip-name $PCF_SSH_LB_IP    

    azure network lb address-pool create $RESOURCE_GROUP $PCF_SSH_LB pcf-vms    

    azure network lb rule create $RESOURCE_GROUP $PCF_SSH_LB diego-ssh --protocol tcp --frontend-port 2222 --backend-port 2222

}

# -------------------------------------------------------------------------------------------------------
# Main Program 
# -------------------------------------------------------------------------------------------------------
usage

ENVIRONMENT="AzureUSGovernment"
echo -e  "Environment Type: 1 - Azure, 2 - AzureUSGovernment"
read -p "Enter 1 or 2 (Press ENTER for 2):: " env
if [ -z $env ]; then
  env=2
fi
if [ $env -eq 1 ]; then
  ENVIRONMENT="Azure"
fi

echo "Start with http://aka.ms/devicelogin"
echo "will spin here until login completes"
# start with http://aka.ms/devicelogin
# will spin here until login completes
# disable login during testing --- 
# azure login   --environment $ENVIRONMENT
 


# ensure ARM mode
#
azure config mode arm

read_subscription_id

TENANTID=`azure account list --json | grep -A6 ${SUBSCRIPTIONID} | tail -1 | awk -F':' '{ print $2 }' | tr -d ',' | tr -d '"' | tr -d ' ' `

echo -e "\033[1;34m Using SUBSCRIPTIONID: $SUBSCRIPTIONID \033[0m"
echo -e "\033[1;34m Using TENANTID: $TENANTID \033[0m"

# for multiple subscriptions, select the appropriate
#
azure account set $SUBSCRIPTIONID

read_inputs_create_resources

echo_inputs
echo_tofile

spinner





