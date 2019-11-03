# Develop an App Service Logic App

## Objectives
* Create a multi-activity workflow.
* Understand how to handle exceptions thrown during app exceution.

## What is Azure Logic App?
Azure Logic Apps implement event-driven serverless, potentially long-running, workflows. They can represent complex processes instead of requiring quick and simple excecution like Azure Funtions.

Logic Apps can be triggered by many different type of events and business actions, and there is extensive and extensible support for integrations with both cloud, internal, and B2B systems. These integrations also can provide built in data transformations in addition to simply triggering those systems.

## Create a Logic App
1. Creat a Storage Account and upload a blob to it.
```powershell
# NOTE: the example reads files from a storage blob and 
# puts a message if they're older than specified

# Set variables
$resourceGroupName = "logicapp-example"
$storageAccountName = "storage-account"
$queueName = "toarchive"
$containerName = "images"
$location = "westus"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l $location

# Create storage account
az storage account create `
 -g $resourceGroupName `
 -n $storageAccountName `
 -l westus `
 --sku Standard_LRS `

# List the primary and secondary keys for a storage account
$key = $(az storage account keys list `
 --account-name $storageAccountName `
 -g $resourceGroupName `
 --query "[0].value" `
 --output tsv)

# Creates a queue under the given account
az storage queue create `
 -n $queueName `
 --account-name $storageAccountName `
 --account-key $key

# Create a container in a storage account
az storage container create `
 --name $containerName `
 --account-name $storageAccountName `
 --account-key $key

# Upload a file to a storage blob
az storage blob upload `
 --container-name $containerName `
 --name image.jpg `
 --file image.jpg `
 --account-name $storageAccountName `
 --account-key $key

# Retrieves one or more messages from the front of the queue
az storage message peek `
 --queue-name $queueName `
 --account-name $storageAccountName `
 --account-key $key `
 --num-messages 10

# Delete resource group
az group delete `
 -n $resourceGroupName `
 --yes
```
2. Create Logic App using the Logic Apps Designer in the Azure Portal.

## Handle Exceptions and Retries
Logic Apps support robust handling/retries activities on error. These can be confiured in boh the GUI and JSON.

Type | Description |
---- | ------------|
Default | This policy sends up to four retries at exponentially increasing intervals, which scale by 7.5 seconds but are capped between 5 and 45 seconds |
Exponential Interval | This policy waits a random interval selected from an exponentially growing range before sending the next request |
Fixed Interval | This policy waits the specified interval before sending the next request |
None | Don't resend the request |

### Concurrency/Scaling
* The Azure Functions runtime will receive up to 16 messages and run functions for each in parallel.
* When the number of messages being processed gets down to 8, the runtime gets another batch of 16 and processes those.
* Any VM processing messages in the function app will only process a maximun of 24 parallel messages.
* There can be a maximun of 16 parallel functions running at any one time and 24 parallel messages pulled out of the queue.

## References
* [App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/).
* [Create an App Service app with deployment from GitHub using Azure CLI](https://docs.microsoft.com/bs-latn-ba/azure/app-service/scripts/cli-deploy-github).
* [Web App for Containers](https://azure.microsoft.com/en-us/services/app-service/containers/).
