# pcf-azure-install

## Pre-requsities
1. Bash 
2. Git
3. Github account
4. 


## Steps to setup Azure Env
1. Using a browser log into your Azure portal
2. Create a new `resource group` and make note of the name. Default name used in scripts is `pcf-rg`
3. `git clone https://github.com/yjayaraman-pivotal/pcf-azure-install.git ` or download https://github.com/yjayaraman-pivotal/pcf-azure-install/archive/master.zip
3. From a terminal window, run setup_azure_env.sh
4. Once the env is setup, using a Browser log into your Azure portal
5. Create a jumpbox (coming soon in the script)
6. SSH into the jumpbox
7. sudo apt-get update && sudo apt-get install git
8. `git clone https://github.com/yjayaraman-pivotal/pcf-azure-install.git ` or download https://github.com/yjayaraman-pivotal/pcf-azure-install/archive/master.zip
9. cd to the directory
10. Run setupbosh.sh
11. Run download_artifacts.sh
12. cd manifests/deployments
13. ssh-keygen -t rsa -f ~/bosh -P "" -C ""
13. modify bosh.yml (to update it with your Azure info, put the ssh info, etc.)

To be continued ....



