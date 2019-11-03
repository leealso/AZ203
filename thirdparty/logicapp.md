# Develop an App Service Logic App

## Objectives
* Create a multi-activity workflow using the Logic Apps Designer.
* Understand how to handle exceptions thrown during app execution.

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

Below an example of an Azure Logic App retry policy JSON:
```json
"<action-name>": {
   "type": "<action-type>", 
   "inputs": {
      "<action-specific-inputs>"
      "retryPolicy": {
         "type": "<retry-policy-type>",
         "interval": "<retry-interval>",
         "count": "<retry-attempts>",
         "minimumInterval": "<minimum-interval>",
         "maximumInterval": "<maximun-interval>"
      },
      "<other-action-specific-inputs>"
   },
   "runAfter": {}
}
```

## Logic Apps vs Functions vs WebJobs vs Flow
* Logic apps are good for event driver processes that integrate with other services. They are also declarative instead of code-first.
* Functions are light-weight and code-first.
* For processing queue messages, Logic Apps, Functions, and WebJobs are all appropiate, but Azure Functions offer more developer productivity than Azure App Service WebJobs does. It also offers more options for programming languages, development environments, Azure service integration, and pricing. For most scenarios, it's the best choice.
* WebJobs have generally been superceded by Functions but are able to run in the same Azure DevOps environment as Web Apps.

## References
* [Overview - What is Azure Logic Apps?](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-overview).
* [Overview: Azure serverless with Azure Logic Apps and Azure Functions](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-serverless-overview).
* [Handle errors and exceptions in Azure Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-exception-handling).
* [What are Microsoft Flow, Logic Apps, Functions, and WebJobs?](https://docs.microsoft.com/en-us/azure/azure-functions/functions-compare-logic-apps-ms-flow-webjobs)
