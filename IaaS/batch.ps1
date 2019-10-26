##############################
# Create and run a batch job #
##############################

$resourceGroupName = "BatchExample"
$storageAccountName = "BatchStorageAccount"
$location = "westus"
$batchAccountName = "BatchAccount"
$poolName = "BatchPool"

# Create Resource Group
az group create `
 -l $location `
 -n $resourceGroupName

# Create Storage Account
az storage account create `
 -g $resourceGroupName `
 -n $storageAccountName `
 -l $location `
 --sku Standard_LRS

# Create Batch Account
az batch account create `
 -n $batchAccountName `
 --storage-account $storageAccountName `
 -g $resourceGroupName `
 -l $location

# Login to the Batch Account
az batch account login `
 -n $batchAccountName `
 -g $resourceGroupName `
 --shared-key-auth

# Create Pool
az batch pool create `
 --id $poolName `
 --vm-size Standard_A1_v2 `
 --target-dedicated-nodes 2 `
 --image `
   canonical:ubuntuserver:16.04-LTS `
 --node-agent-sku-id `
   "batch.node.ubuntu 16.04"

# Get status of a Pool
az batch pool show `
 --pool-id $poolName `
 --query "allocationState"

# Create Job
az batch job create `
 --id myjob `
 --pool-id $poolName

# Get status of a Job
az batch job show `
 --job-id myjob

# Create Tasks
for ($i=0; $i -lt 4; $i++) {
    az batch task create `
     --task-id mytask$i `
     --job-id myjob `
     --command-line "/bin/bash -c 'printenv | grep AZ_BATCH; sleep 90s'" 
}

# Get status of a Task
az batch task show `
 --job-id myjob `
 --task-id mytask1

# Get a list of a Task's output files
az batch task file list `
 --job-id myjob `
 --task-id mytask1 `
 --output table

# Download a Task's output file to a local directory
az batch task file download `
 --job-id myjob `
 --task-id mytask0 `
 --file-path stdout.txt `
 --destination ./stdout0.txt

# Delete Pool
az batch pool delete -n $poolName

# Delete Resource Group
az group delete -n $resourceGroupName


################################################
# Add an application to an Azure Batch account #
################################################

# Create a new application
az batch application create \
    --resource-group resourceGroupName \
    --name batchAccountName \
    --application-id myapp \
    --display-name "My Application"

# An application can reference multiple application executable packages
# of different versions. The executables and any dependencies need
# to be zipped up for the package. Once uploaded, the CLI attempts
# to activate the package so that it's ready for use
az batch application package create \
    --resource-group resourceGroupName \
    --name batchAccountName \
    --application-id myapp \
    --package-file my-application-exe.zip \
    --version 1.0

# Update the application to assign the newly added application
# package as the default version
az batch application set \
    --resource-group resourceGroupName \
    --name batchAccountName \
    --application-id myapp \
    --default-version 1.0