# pcf-azure-install

## This script is 'opinionated' and makes the following assumptions:
 1.  Azure CLI is installed on this machine
 2.  You need to have a valid 'SubscriptionID'
 3.  You need to have a valid 'ResourceGroup' created in the 'Location' of choice
 4.  You need to enough quota to create VMs 'azure vm list-usage --location <location>'

[NOTE]
If you are running windows desktop, install virtualBox and Vagrant and create a Lucid64 box 

## Usage
./create-azure-env.sh <Parameters>
 
 Parameters:
 - --help Display these options
 - --dry-run Skip creating any resources
 - --test Just generate the files based on defaults
 - --skip-login Skip logging into Azure and re-use the existing login
 - --prefix <value> Enter a prefix for skipping inputs
 - --subscription <value> Enter Azure SubscriptionID
 - --resource-group <value> Enter Azure Resource Group
 - --location <value> Enter Azure Location (e.g. usgoviowa)

## Steps to setup Azure Env
1. ./create-azure-env.sh script creates all the required Azure resources and generates config files needed for PCF install in the 'temp' directory:

2. Next step is to create 'A' records in your DNS registry
 Create an 'A' record in your DNS registry to point your <domain-name> to
 Create an 'A' record in your DNS registry to point your ssh.<domain-name> to

3. The script also creates an Ubuntu 14 Jumpbox using Azure Portal and copies the config files and scripts to the jumpbox under ~/pcf-azure-install directory

3. SSH on to the jumpbox

4. Run the following commands:
 - cd ~/pcf-azure-install/scripts
 - sudo ./setupbosh.sh
 - ./download_artifacts.sh
 - ./deploy_bosh_director.sh
 - ./deploy_pcf.sh
 - ./deploy_all.sh
 
 
