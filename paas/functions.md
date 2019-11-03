# Create Azure Functions

## Objectives
* Identify if a function is triggered by Storage Queue messages, and if it outputs to a Storage Table.
* Understand how the queue trigger handles receiving/scaling message processing.
* Understand how the queue trigger handles exceptions thrown within the function.

## What is Azure Functions?
Azure Functions are an implementation of "serverless computing" that allows running of code on-demand. Functions are event-driven and short-lived, and provide for automatic scalability to meet demand.

## Create a Queue Triggered Function with Table Output
1. Create a Storage Queue a put a message.
```powershell
# Set variables
$resourceGroupName = "functions-example"
$storageAccountName = "storage-account"
$queueName = "incoming-orders"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l $location

# Create Storage Account
az storage account create `
 -g $resourceGroupName `
 -n $storageAccountName `
 -l westus `
 --sku Standard_LRS `
 --kind StorageV2 `
 --access-tier Hot

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

# Get Storage Account connection string
az storage account show-connection-string `
 -n $storageAccountName `
 --query "conectionString"

$order1json = Get-Content -Path order1.json

# Adds a new message to the back of the message queue
az storage message put `
 --account-name $storageAccountName `
 --account-key $key `
 --queue-name $queueName `
 --content $order1json

# Delete resource group
az group delete `
 --name resourceGroupName `
 --yes `
 --no-wait
```

2. Create a function triggered by a queue and outputs to Storage Table.
```csharp
using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage.Queue;
using Microsoft.WindowsAzure.Storage.Table;
using Newtonsoft.Json;

namespace az203.paas.functions
{
    public static class OrderProcessor
    {
        [FunctionName("ProcessOrders")]
        public static void ProcessOrders(
            [QueueTrigger("incoming-orders", Connection = "AzureWebJobsStorage")],
            CloudQueueMessage queueItem,
            [Table("Orders", Connection = "AzureWebJobsStorage")]
            ICollector<Order> tableBindings,
            ILogger log)
        {
            log.LogInformation($"Processing Order (mesage Id): {queueItem.Id}");
            log.LogInformation($"Processing at: {DateTime.UtcNow}");
            log.LogInformation($"Queue Insertion Time: {queueItem.InsertionTime}");
            log.LogInformation($"Queue Insertion Time: {queueItem.ExpirationTime}");
            log.LogInformation($"Data: {queueItem.AsString}");
            tableBindings.Add(JsonConvert.DeserializeObject<Order>(queueItem.AsString));
        }

        [FunctionName("ProcessOrders-Poison")]
        public static void ProcessFailedOrders(
            [QueueTrigger("incoming-orders-poison", Connection = "AzureWebJobsStorage")]
            CloudQueueMessage queueItem, 
            ILogger log)
        {
            log.LogInformation($"C# Queue trigger function processed: {queueItem}");
            log.LogInformation($"Data: {queueItem.AsString}");
        }
    }
}
```

Packages required:
* [Microsoft.Azure.WebJobs.Extensions.EventGrid](https://www.nuget.org/packages/Microsoft.Azure.WebJobs.Extensions.EventGrid)
* [Microsoft.NET.Sdk.Functions](https://www.nuget.org/packages/Microsoft.NET.Sdk.Functions)
* [Microsoft.Azure.WebJobs.Extensions.Storage](https://www.nuget.org/packages/Microsoft.Azure.WebJobs.Extensions.Storage)

## References
* [App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/).
* [Create an App Service app with deployment from GitHub using Azure CLI](https://docs.microsoft.com/bs-latn-ba/azure/app-service/scripts/cli-deploy-github).
* [Web App for Containers](https://azure.microsoft.com/en-us/services/app-service/containers/).
