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
        tewm 0.1
    done
  done
}

yesnodelete()
{

  local Y_N
  while [ -z $Y_N ]
  do
      read -p "Do you want to continue[y/n/d]: y - continue, n - abort, d - delete?  " Y_N

      case "$Y_N" in
              d)
                  echo $Y_N
                  ;;
               
              y)
                  echo $Y_N
                  ;;
               
              n)
                  echo $Y_N
                  ;;
               
              *)
                  Y_N=""
       
      esac
  done
}

echo_tofile()
{

  local FILENAME="temp/create_azure.txt"
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
  echo "PUBLIC_IP=$PUBLIC_IP " >&3
  echo "PCF_SSH_LB=$PCF_SSH_LB " >&3
  echo "PUBLIC_SSH_IP=$PUBLIC_SSH_IP " >&3

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
  echo "*   PUBLIC_IP          :    $PUBLIC_IP " 
  echo "*   PCF_SSH_LB         :    $PCF_SSH_LB " 
  echo "*   PUBLIC_SSH_IP      :    $PUBLIC_SSH_IP "                                                                                    
  echo "*   PREFIX             :    $PREFIX "                                                                              
  echo "*************************************************************************************"


}

usage() 
{
  echo -e "\033[1;92m # This script is 'opinionated' and makes the following assumptions:" 
  echo -e "\033[1;92m #   1.  Azure CLI is installed on this machine \033[0m"
  echo -e "\033[1;92m #   2.  You need to have a valid 'SubscriptionID' \033[0m"
  echo -e "\033[1;92m #   3.  You need to have a valid 'ResourceGroup' created in the 'Location' of choice  \033[0m"
  echo	
  echo -e "\033[1;92m Parameters: \033[0m"
  echo -e "\033[1;92m --dry-run Skip creating any resources \033[0m"
  echo -e "\033[1;92m --test Just generate the files based on defaults \033[0m"
  echo -e "\033[1;92m --skip-login Skip logging into Azure and re-use the existing login \033[0m"
  echo -e "\033[1;92m --prefix <value> Enter a prefix for skipping inputs \033[0m"
  echo -e "\033[1;92m --subscription <value> Enter Azure SubscriptionID \033[0m"
  echo -e "\033[1;92m --resource-group <value> Enter Azure Resource Group \033[0m"
  echo -e "\033[1;92m --location <value> Enter Azure Location (e.g. usgoviowa) \033[0m"
}

create_service_principal() 
{
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    CLIENTID="dry-run"
    return
  fi

  # client-secret		CLIENT-SECRET
  #
  #CLIENTSECRET=`openssl rand -base64 16 | tr -dc _A-z-a-z-0-9`  

  # "application Id"	 CLIENT-ID
  #  

  CLIENTID=`azure ad app create --name "$PCFBOSHNAME" --password "$CLIENTSECRET" --identifier-uris ""$IDURIS"" --home-page ""$HOMEPAGE"" | grep  "AppId:" | awk -F':' '{ print $3 } ' | tr -d ' '`  
   
  sleep 10

  azure ad sp create --applicationId $CLIENTID  
 
  sleep 10

  azure role assignment create --roleName "Contributor"  --spn "$SPNAME" --subscription $SUBSCRIPTIONID

}

read_subscription_id()
{
      if [ -n "$SUBSCRIPTIONID" ]; then
        SUBSCRIPTIONID=`azure account list | grep -w $SUBSCRIPTIONID | grep -w "Enabled"  | awk -F '[ ][ ]+' '{ print $3 }'  `
      fi
  while [ -z $SUBSCRIPTIONID ]; do
      echo
      azure account list | grep -w "Enabled" | awk -F '[ ][ ]+' '{ print $3 }'
      echo 

      read -p "Enter SUBSCRIPTIONID from the list above : " SUBSCRIPTIONID
      if [ -n "$SUBSCRIPTIONID" ]; then
        SUBSCRIPTIONID=`azure account list | grep -w $SUBSCRIPTIONID | grep -w "Enabled"  | awk -F '[ ][ ]+' '{ print $3 }'  `
      fi
  done
}

read_location() 
{
    if [ -n "$LOCATION" ]; then
      LOCATION=`azure location list | grep -w $LOCATION | awk -F ':' '{ print $3 }' | tr -d ' ' ` 
    fi
    while [ -z $LOCATION ]; do
      echo
      azure location list | grep Location | awk -F ':' '{ print $3 }' | tr -d ' '
      echo
      read -p "Enter the location from the list above: " LOCATION 
      if [ -n "$LOCATION" ]; then
        LOCATION=`azure location list | grep -w $LOCATION | awk -F ':' '{ print $3 }' | tr -d ' ' ` 
        echo -e "Using location: $LOCATION" 
      fi

    done 
}
read_resource_group()
{
    if [ -n "$RESOURCE_GROUP" ]; then
        if [ -n "$DRYRUN" ]; then
          echo "--dry-run is $DRYRUN skipping resource group check"
          return
        fi
        RESOURCE_GROUP=`azure group list | grep -w " $RESOURCE_GROUP " | awk -F '[ ][ ]+' '{ print $2 }'  ` 
    fi
    while [ -z $RESOURCE_GROUP ]; do
      echo
      azure group list | awk -F '[ ][ ]+' '{ print $2 }'
      echo
      read -p "Enter the Resource Group from the list above: " RESOURCE_GROUP 
      if [ -n "$RESOURCE_GROUP" ]; then
        RESOURCE_GROUP=`azure group list | grep -w " $RESOURCE_GROUP " | awk -F '[ ][ ]+' '{ print $2 }'  `
        echo -e "Using resource group: $RESOURCE_GROUP"
      fi
    done
}
read_service_principal()
{
    while [ -z $CLIENTID ]; do
      if [ -n "$PREFIX" ]; then
        IDURIS=http://"$PREFIX"pcfbosh
      else
        read -p "Enter Service Principal App URI: (Press ENTER for http://pcfbosh): " IDURIS
      fi    
      if [ -z $IDURIS ]; then
          IDURIS="http://pcfbosh"
      fi  
      PCFBOSHNAME=${IDURIS:7}
      HOMEPAGE=$IDURIS
      SPNAME=$IDURIS 
      CLIENTSECRET="keepitsimple"
      CLIENTID=`azure ad app show --identifierUri $IDURIS | grep  -w AppId | awk -F':' '{print $3}' | tr -d ' '`
      local OBJECTID=`azure ad app show --identifierUri $IDURIS | grep  -w ObjectId | awk -F':' '{print $3}' | tr -d ' '`
      if [ -n "$CLIENTID" ]; then
         echo
         echo " Service Principal exists for $IDURIS "
         local Y_N=`yesnodelete`
         if [ $Y_N = 'd' ]; then
            azure ad app delete $OBJECTID
            CLIENTID=""
         fi
      fi 

      if [ -z "$CLIENTID" ]; then
        create_service_principal
      fi       
#      local TEMPSTR=`azure login --username  $CLIENTID  --password $CLIENTSECRET --service-principal --tenant $TENANTID —environment $ENVIRONMENT | grep "login command OK" `
#      if [ -z "$TEMPSTR" ]; then
#          error "Unable to login using --username  $CLIENTID  --password $CLIENTSECRET --service-principal --tenant $TENANTID —environment $ENVIRONMENT "
#          CLIENTID=""
#      fi

    done
}

read_nsg()
{
  if [ -n "$PREFIX" ]; then
    PCF_NSG="$PREFIX"_nsg
  else
     read -p "Enter PCF Network Security Group Name: (Press ENTER for pcf-nsg): " PCF_NSG
  fi
  if [ -z $PCF_NSG ]; then
      PCF_NSG="pcf-nsg"
  fi
  local z=$PCF_NSG
  PCF_NSG=`azure network nsg list | grep -w $PCF_NSG |  grep -w $LOCATION | awk -F '[ ][ ]+' '{ print $2 }'`
  if [ -n "$PCF_NSG" ]; then
      echo
      echo -e "NSG exists for $PCF_NSG"
      local Y_N=`yesnodelete`
      if [ $Y_N = 'd' ]; then
        azure network nsg delete $RESOURCE_GROUP $PCF_NSG $LOCATION
        PCF_NSG=""
      fi
  fi 
  if [ -z "$PCF_NSG" ]; then
    PCF_NSG=$z
    create_nsg
  fi

}

read_vnet()
{
  if [ -n "$PREFIX" ]; then
    PCF_NET="$PREFIX"-net
  else
    read -p "Enter PCF VNET Name: (Press ENTER for pcf-net): " PCF_NET
  fi
  if [ -z $PCF_NET ]; then
      PCF_NET="pcf-net"
  fi 
  
  if [ -n "$PREFIX" ]; then
    PCF_SUBNET="$PREFIX"
  else
    read -p "Enter PCF SUBNET Name: (Press ENTER for pcf): " PCF_SUBNET
  fi

  if [ -z $PCF_SUBNET ]; then
     PCF_SUBNET="pcf"
  fi 
  local z=$PCF_NET
  PCF_NET=`azure network vnet list | grep -w $PCF_NET |  grep -w $LOCATION | awk -F '[ ][ ]+' '{ print $2 }'`
  if [ -n "$PCF_NET" ]; then
      echo
      echo -e "VNET exists for $PCF_NET"
      local Y_N=`yesnodelete`
      if [ $Y_N = 'd' ]; then
        azure network vnet delete $RESOURCE_GROUP $PCF_NET
        PCF_NET=""
      else
          read -p "Enter PCF SUBNET Name: (Press ENTER for pcf): " PCF_SUBNET
          if [ -z $PCF_SUBNET ]; then
             PCF_SUBNET="pcf"
          fi         
      fi
  fi 
  if [ -z "$PCF_NET" ]; then
    PCF_NET=$z
    create_vnet
  fi
}


read_storage()
{
  if [ -n "$PREFIX" ]; then
    STORAGE_NAME="$PREFIX"san
  fi
  
while [ -z $STORAGE_NAME ]; do
    read -p "Enter Storage Account Name: " STORAGE_NAME
  done
  local z=$STORAGE_NAME
  #CONNECTIONSTRING=`azure storage account connectionstring show $STORAGE_NAME  --resource-group $RESOURCE_GROUP | grep connectionstring: | cut -f3 -d':' | tr -d " "`   
  STORAGE_NAME=`azure storage account list | grep -w $STORAGE_NAME |  awk -F '[ ][ ]+' '{ print $2}'`

  if [ -n "$STORAGE_NAME" ]; then
      echo
      echo "Storage exists for $STORAGE_NAME"
      local Y_N=`yesnodelete`
      if [ $Y_N = 'd' ]; then
        azure storage account delete $STORAGE_NAME --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTIONID
        STORAGE_NAME=""
      fi
  fi 
  if [ -z "$STORAGE_NAME" ]; then
    STORAGE_NAME=$z
    create_storage
  fi
}

read_xtrastorage()
{
   if [ -n "$PREFIX" ]; then
    XTRA_STORAGE_NAME=xtra"$PREFIX"san
  fi
     while [ -z $XTRA_STORAGE_NAME ]; do
      read -p "Enter Extra Storage Account Name: " XTRA_STORAGE_NAME
    done 
    local z=$XTRA_STORAGE_NAME
    local loop=1
    while [ $loop -le 3 ]
    do
      XTRA_STORAGE_NAME=`azure storage account list | grep -w $XTRA_STORAGE_NAME$loop |  awk -F '[ ][ ]+' '{ print $2}'`  
      if [ -n "$XTRA_STORAGE_NAME" ]; then
        echo
        echo -e "Storage exists for $XTRA_STORAGE_NAME"
        local Y_N=`yesnodelete`
        if [ $Y_N = 'd' ]; then
          azure storage account delete $XTRA_STORAGE_NAME --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTIONID
          XTRA_STORAGE_NAME=""
        fi
      fi 
      if [ -z "$XTRA_STORAGE_NAME" ]; then
       XTRA_STORAGE_NAME=$z
       create_xtra_storage $loop
      fi 
      #Increment the loop
      loop=$((loop + 1)) 
      XTRA_STORAGE_NAME=$z
    done


}

read_lb()
{
  if [ -n "$PREFIX" ]; then
    PCF_LB="$PREFIX"-lb
  else 
    read -p "Enter LB Name: (Press ENTER for pcf-lb): " PCF_LB
  fi

    if [ -z $PCF_LB ]; then
       PCF_LB="pcf-lb"
    fi    

    if [ -n "$PREFIX" ]; then
      PCF_LB_IP="$PREFIX"-lb-ip
    else 
     read -p "Enter Public IP name associated with this load balancer: (Press ENTER for pcf-lb-ip): " PCF_LB_IP
    fi
    if [ -z $PCF_LB_IP ]; then
      PCF_LB_IP="pcf-lb-ip"
    fi    

    if [ -n "$PREFIX" ]; then
      PCF_FE_IP="$PREFIX"-fe-ip
    else 
     read -p "Enter LB Frontend IP Name: (Press ENTER for pcf-fe-ip): " PCF_FE_IP
    fi
    if [ -z $PCF_FE_IP ]; then
       PCF_FE_IP="pcf-fe-ip"
    fi

  local z=$PCF_LB
  PCF_LB=`azure network lb list  $RESOURCE_GROUP | grep -w $PCF_LB | awk -F '[ ][ ]+' '{ print $2}'`
  if [ -n "$PCF_LB" ]; then
      echo
      echo "Load Balancer exists for $PCF_LB"
      local Y_N=`yesnodelete`

      if [ $Y_N = 'd' ]; then
        azure network lb delete $RESOURCE_GROUP $PCF_LB $LOCATION
        PCF_LB=""
      else
        PUBLIC_IP=`azure network public-ip show $RESOURCE_GROUP $PCF_LB_IP | grep "IP Address" | cut -f3 -d":" | tr -d ' '`
      fi
  fi 
  if [ -z "$PCF_LB" ]; then
    PCF_LB=$z
    create_lb
  fi
}

read_ssh_lb()
{
    if [ -n "$PREFIX" ]; then
      PCF_SSH_LB="$PREFIX"-ssh-lb
    else 
      read -p "Enter SSH LB Name: (Press ENTER for pcf-ssh-lb): " PCF_SSH_LB
    fi
    if [ -z $PCF_SSH_LB ]; then
       PCF_SSH_LB="pcf-ssh-lb"
    fi    
    
    if [ -n "$PREFIX" ]; then
      PCF_SSH_LB_IP="$PREFIX"-ssh-lb-ip
    else 
       read -p "Enter Public IP name associated with this load balancer: (Press ENTER for pcf-ssh-lb-ip): " PCF_SSH_LB_IP
    fi
    if [ -z $PCF_SSH_LB_IP ]; then
      PCF_SSH_LB_IP="pcf-ssh-lb-ip"
    fi 

     if [ -n "$PREFIX" ]; then
      PCF_SSH_FE_IP="$PREFIX"-ssh-fe-ip
    else 
     read -p "Enter SSH LB Frontend IP Name: (Press ENTER for pcf-ssh-fe-ip): " PCF_SSH_FE_IP
    fi
    if [ -z $PCF_SSH_FE_IP ]; then
       PCF_SSH_FE_IP="pcf-ssh-fe-ip"
    fi

  local z=$PCF_SSH_LB
  PCF_SSH_LB=`azure network lb list  $RESOURCE_GROUP | grep -w $PCF_SSH_LB | awk -F '[ ][ ]+' '{ print $2}'`
  if [ -n "$PCF_SSH_LB" ]; then
      echo
      echo "Load Balancer exists for $PCF_SSH_LB"
      local Y_N=`yesnodelete`
      if [ $Y_N = 'd' ]; then
        azure network lb delete $RESOURCE_GROUP $PCF_SSH_LB $LOCATION
        PCF_SSH_LB=""
      else
        PUBLIC_SSH_IP=`azure network public-ip show $RESOURCE_GROUP $PCF_SSH_LB_IP | grep "IP Address" | cut -f3 -d":" | tr -d ' '`

      fi
  fi 
  if [ -z "$PCF_SSH_LB" ]; then
    PCF_SSH_LB=$z
    create_ssh_lb
  fi
}

read_inputs_create_resources()
{

    read_location
#    echo -e "\033[1;34m Using location: $LOCATION \033[0m"

    read_resource_group
#    echo -e "\033[1;34m Using ResourceGroup: $RESOURCE_GROUP \033[0m"

    echo -e "\033[1;34m Creating Service Principal \033[0m"
    read_service_principal  
#    echo -e "\033[1;34m Using Service Principal: $IDURIS \033[0m"

    echo -e "\033[1;34m Creating Network Security Groups \033[0m"
    read_nsg  
#    echo -e "\033[1;34m Using NSG: $PCF_NSG \033[0m"
   
    echo -e "\033[1;34m Creating VNETs \033[0m"
    read_vnet
#    echo -e "\033[1;34m Using VNET: $PCF_NET \033[0m"
#    echo -e "\033[1;34m Using SUBNET: $PCF_SUBNET \033[0m"

    create_jumpbox

    echo -e "\033[1;34m Creating Storage Accounts \033[0m"
    read_storage
#    echo -e "\033[1;34m Using Storage: $STORAGE_NAME \033[0m"
    read_xtrastorage
#    echo -e "\033[1;34m Using Extra Storage: $XTRA_STORAGE_NAME \033[0m"

    echo -e "\033[1;34m Creating Load Balancers \033[0m"
    read_lb
#    echo -e "\033[1;34m Using LB: $PCF_LB \033[0m"
    read_ssh_lb
#    echo -e "\033[1;34m Using SSH LB: $PCF_SSH_LB \033[0m"

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
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    return
  fi
    azure network nsg create $RESOURCE_GROUP $PCF_NSG $LOCATION 
    azure network nsg rule create $RESOURCE_GROUP $PCF_NSG internet-to-lb --protocol Tcp --priority 100 --destination-port-range '*'   
}

create_vnet()
{
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    return
  fi
  azure network vnet create $RESOURCE_GROUP $PCF_NET $LOCATION --address-prefixes 10.0.0.0/16   
  azure network vnet subnet create $RESOURCE_GROUP $PCF_NET $PCF_SUBNET --address-prefix 10.0.0.0/20   

}

create_jumpbox()
{
  if [ -n "$DRYRUN" ]; then
      echo "--dry-run is $DRYRUN skipping jumpbox create"
      return
  fi
  while [ -z $JUMPPASSWORD ]; do
      read -p "Enter Jump Box Admin Password (At least 8 characters and must contain uppercase, lowercase, numbers, and special chars) : " JUMPPASSWORD
  done
  azure vm create -vv --resource-group $RESOURCE_GROUP --location $LOCATION --os-type Linux --image-urn UbuntuLTS --admin-username ubuntu --admin-password $JUMPPASSWORD --vm-size Standard_D1_v2 --vnet-name $PCF_NET --vnet-subnet-name $PCF_SUBNET --nic-name pcf-jump-nic --public-ip-name jump-public-ip --public-ip-domain-name pcf-jump pcf-jump
}

create_storage()
{
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    return
  fi
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
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    return
  fi
      azure storage account create $XTRA_STORAGE_NAME$1 --resource-group $RESOURCE_GROUP --sku-name LRS --kind Storage --subscription $SUBSCRIPTIONID  --location $LOCATION    

      CONNECTIONSTRING=`azure storage account connectionstring show $XTRA_STORAGE_NAME$1  --resource-group $RESOURCE_GROUP | grep connectionstring: | cut -f3 -d':' | tr -d " "`    

      if [ -z $CONNECTIONSTRING ]; then
        error "Unable to get Connection String for Storage Account $XTRA_STORAGE_NAME$1"
        exit
      fi    

      azure storage container create bosh --connection-string $CONNECTIONSTRING    

      azure storage container create stemcell --permission blob --connection-string $CONNECTIONSTRING 

}

create_lb()
{
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    return
  fi
    azure network lb create $RESOURCE_GROUP $PCF_LB $LOCATION    



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
  if [ -n "$DRYRUN" ]; then
    echo "--dry-run is $DRYRUN skipping create"
    return
  fi  
    azure network lb create $RESOURCE_GROUP $PCF_SSH_LB $LOCATION    

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

create_sed_commands()
{
 
  local FILENAME="temp/bosh.txt"
  # Opening file descriptors # 3 for reading and writing
  # i.e. /tmp/out.txt
  exec 3<>$FILENAME

  # Write to file
  echo s/__DISK_SIZE__/50000/g >&3
  echo s/__PCF_NET__/$PCF_NET/g >&3
  echo s/__PCF_SUBNET__/$PCF_SUBNET/g >&3
  echo s/__BOSH_IP__/$BOSH_IP/g >&3
  echo s/__ENVIRONMENT__/$ENVIRONMENT/g >&3
  echo s/__SUBSCRIPTION_ID__/$SUBSCRIPTIONID/g >&3
  echo s/__TENANTID__/$TENANTID/g >&3
  echo s/__CLIENTID__/$CLIENTID/g >&3
  echo s/__CLIENTSECRET__/$CLIENTSECRET/g >&3
  echo s/__RESOURCE_GROUP__/$RESOURCE_GROUP/g >&3
  echo s/__STORAGE_NAME__/$STORAGE_NAME/g >&3
  echo s/__PCF_NSG__/$PCF_NSG/g >&3
  echo s/__XTRA_STORAGE_NAME__/$XTRA_STORAGE_NAME/g >&3
  echo s/__PCF_LB__/$PCF_LB/g >&3
  echo s/__PCF_SSH_LB__/$PCF_SSH_LB/g >&3

  # close fd # 3
  exec 3>&-
}
generate_bosh_yml()
{
    echo -e "\033[1;34m Generating BOSH Director config \033[0m"

    while [ -z $BOSH_IP ];
    do
      read -p "Enter an IP for BOSH Director VM: (Press ENTER for 10.0.0.10): " BOSH_IP
      if [ -z $BOSH_IP ]; then
        BOSH_IP="10.0.0.10"
      fi 
    done

    create_sed_commands

  sed -f temp/bosh.txt<../templates/bosh.cnf > temp/bosh.tmp
  sed -f temp/bosh.txt < ../templates/cloud_config.cnf > temp/cloud_config.yml
  sed -f temp/bosh.txt < ../templates/cf.cnf > temp/cf.tmp

    ssh-keygen -t rsa -f temp/bosh -P "" -C ""
    BOSH_PUB_CERT=$(<temp/bosh.pub)
    echo "Public cert is $BOSH_PUB_CERT"
    awk -v var="$BOSH_PUB_CERT" '{ sub(/__BOSH_PUB_CERT__/, var, $0) }1' temp/bosh.tmp >temp/bosh.yml  

}

echo_next_steps()
{
echo
echo -e "\033[1;92m This script creates all the required Azure resources and generates config files needed for PCF install in the 'temp' directory: \033[0m" 
echo
echo -e "\033[1;92m Next step is to create 'A' records in your DNS registry \033[0m" 
echo -e "\033[1;34m Create an 'A' record in your DNS registry to point your <domain-name> to $PUBLIC_IP \033[0m" 
echo -e "\033[1;34m Create an 'A' record in your DNS registry to point your ssh.<domain-name> to $PUBLIC_SSH_IP \033[0m" 
echo 
echo -e "\033[1;92m The script also creates an Ubuntu 14 Jumpbox using Azure Portal \033[0m" 
echo -e "\033[1;92m and copies the config files and scripts to the jumpbox under ~/pcf-azure-install directory  \033[0m" 
echo
echo -e "\033[1;34m SSH on to the jumpbox \033[0m" 
echo
echo -e "\033[1;92m Run the following commands: \033[0m" 
echo -e "\033[1;34m cd ~/pcf-azure-install/scripts \033[0m"  
echo -e "\033[1;34m sudo ./setupbosh.sh \033[0m" 
echo -e "\033[1;34m ./download_artifacts.sh \033[0m"   
echo -e "\033[1;34m ./deploy_bosh_director.sh \033[0m"   
echo -e "\033[1;34m ./deploy_pcf.sh \033[0m"   
echo 
}


# -------------------------------------------------------------------------------------------------------
# Main Program 
# -------------------------------------------------------------------------------------------------------

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--skip-login)
        SKIPLOGIN=true
        #shift # past argument
        ;;
    -h|--help)
        HELP=true
        #shift # past argument
        ;;
    -n|--dry-run)
        DRYRUN=true
        #shift # past argument
        ;;
    -t|--test)
        TESTRUN=true
        #shift # past argument
        ;;
    -p|--prefix)
        shift # past argument
        PREFIX=$1
        ;;
    -s|--subscription)
        shift # past argument
        SUBSCRIPTIONID=$1
        ;;
    -r|--resource-group)
        shift # past argument
        RESOURCE_GROUP=$1
        ;;
    -l|--location)
        shift # past argument
        LOCATION=$1
        ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

usage


mkdir -p temp

rm -rf temp/*

if [ -n "$HELP" ]; then
     echo_next_steps
     exit
fi

if [ -n "$TESTRUN" ]; then
   ENVIRONMENT=AzureUSGovernment  
   SUBSCRIPTIONID=a019ce4c-2477-46e5-827a-353b099913f5  
   TENANTID=b972ffb6-1ec1-4252-9645-dd27243326c5  
   IDURIS=http://yjpcf 
   HOMEPAGE=http://yjpcf  
   PCFBOSHNAME=yjpcf  
   CLIENTID=dry-run  
   CLIENTSECRET=keepitsimple  
   RESOURCE_GROUP=yj-rg  
   LOCATION=usgoviowa  
   PCF_NET=yj-net  
   PCF_SUBNET=yj-subnet  
   PCF_NSG=yj-nsg  
   STORAGE_NAME=yjs  
   XTRA_STORAGE_NAME=xyjs 
   PCF_LB=yj-l  
   PCF_SSH_LB=yj-s-l 
   PUBLIC_IP="13.72.184.195" 
   PCF_SSH_LB=pcf-ssh-lb 
   PUBLIC_SSH_IP="13.72.190.99"
   BOSH_IP="10.0.0.10"
   DRYRUN=true
   PREFIX="test"
   read_inputs_create_resources
   generate_bosh_yml
   echo_inputs
   echo_tofile
   echo_next_steps
   exit
fi

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

if [ -z "$SKIPLOGIN" ]; then
  azure login   --environment $ENVIRONMENT
fi
 


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

generate_bosh_yml

if [ -z "$DRYRUN" ]; then
  echo -e "\033[1;92m Copying files to the jumpbox. Enter $JUMPPASSWORD as password when prompted: \033[0m" 
  scp -r ../../pcf-azure-install ubuntu@13.72.184.195:.
fi



echo_inputs

echo_tofile

echo_next_steps

#spinner





