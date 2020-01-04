# Develop Message Based Solutions

## Objectives
* Creating a service bus namespace and queue with CLI.
* Sending and receiving messages with C#.
* Understand concepts in message correlation.

## What is Service Bus?
Azure Service Bus povides a fully managed enterprise message broker. It is commonly used to build decoupled applications and services.

Services Bus provides many benefits over Azure Table Queues, including not only queues but topics for multicast-delivery.

Other benefits include session management, routing, dead-lettering, scheduling, deferral, transactions, and many others. But this also adds significatn cost comparred to Table Storage Queues.

<p align="center">
    <img src="https://docs.microsoft.com/en-us/azure/service-bus-messaging/media/service-bus-messaging-overview/about-service-bus-queue.png"/>
</p>

<p align="center">
    <img src="https://docs.microsoft.com/en-us/azure/service-bus-messaging/media/service-bus-messaging-overview/about-service-bus-topic.png"/>
</p>

### Characteristics
* Event Grid gives you reliable event delivery at **massive scale** (scales automatically and the cost per message is lower than Service Bus).
* Simplify event delivery by providing multiple protocols being HTTP webhooks the most common one.
* Example uses: serverless application architectures, **ops automation**, or application integration.

### Concepts
There are five main concepts in Azure Event Grid:
* **Events** - What happened.
* **Event sources** - Where the event took place.
* **Topics** - The endpoint where publishers send events.
* **Event subscriptions** - The endpoint or built-in mechanism to route events, sometimes to more than one handler. Subscriptions are also used by handlers to intelligently filter incoming events.
* **Event handlers** - The app or service reacting to the event.

## Create an event subscription
1. Create a Search Service ang get access keys.
```powershell
$resourceGroup = "eventgrid"
$location = "westus"
$storageAccount = "laaz203egsa"

az group create `
    -n $resourceGroup 
    -l $location

az storage account create `
    -n $storageAccount `
    -g $resourceGroup `
    -l $location `
    --sku Standard_LRS `
    --kind StorageV2 

$storageAccountKey = $(
    az storage account keys list `
        -g $resourceGroup `
        --account-name $storageAccount `
        --query "[0].value" `
        --output tsv
)

$storageAccountID = $(
    az storage account show `
        -n $storageAccount `
        -g $resourceGroup `
        --query id `
        --output tsv
)

az eventgrid event-subscription create `
    --source-resource-id $storageAccountID `
    --name storagesubscription `
    --endpoint-type WebHook `
    --endpoint "https://mywebhook.com/api/test" `
    --included-event-types "Microsoft.Storage.BlobCreated" `
    --subject-begins-with "/blobServices/default/containers/testcontainer/"

az storage container create `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --name testcontainer

az storage blob upload `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --file testfile.txt `
     --container-name testcontainer  `
     --name testfile.txt
  
az storage blob delete `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --container-name testcontainer  `
    --name testfile.txt
  
az eventgrid event-subscription delete `
    --resource-id $storageAccountID `
    --name storagesubscription 

az group delete 
    -n $resourceGroup 
    --yes
```

## References
* [Event Grid](https://azure.microsoft.com/en-us/services/event-grid/).
* [What is Azure Event Grid?](https://docs.microsoft.com/en-us/azure/event-grid/overview)
* [Choose between Azure messaging services - Event Grid, Event Hubs, and Service Bus](https://docs.microsoft.com/en-us/azure/event-grid/compare-messaging-services).
* [Azure Event Grid Viewer](https://docs.microsoft.com/en-us/samples/azure-samples/azure-event-grid-viewer/azure-event-grid-viewer/).
* [Azure CLI samples for Event Grid](https://docs.microsoft.com/en-us/azure/event-grid/cli-samples).
* [The Reactive Manifesto](https://www.reactivemanifesto.org).
* [AThe Twelve-Factor App](https://12factor.net).