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


## Create a Service Bus queue using Azure CLI and Powershell
```powershell
# Set variables
$resourceGroup = "servicebus"
$location = "westus"
$serviceBusNamespace = "az203sb"
$queueName = "queue"

# Create a new resource group
az group create `
    -n $resourceGroup `
    -l $location

# Create a Service Bus Namespace
az servicebus namespace create `
    --n $serviceBusNamespace `
    -g $resourceGroup

# List the keys and connection strings of Authorization Rule for Service Bus Namespace
az servicebus namespace authorization-rule keys list `
    -g $resourceGroup `
    --namespace-name $serviceBusNamespace `
    --name RootManageSharedAccessKey `
    --query primaryConnectionString

# Create the Service Bus Queue
az servicebus queue create `
    --namespace-name $serviceBusNamespace `
    -g $resourceGroup `
    -n $queueName 

# Creates a Service Bus queue in the specified Service Bus namespace
New-AzureRmServiceBusQueue `
    -ResourceGroupName $resourceGroup `
    -NamespaceName $serviceBusNamespace `
    -name $queueName `
    -EnablePartitioning $false
```

## References
* [Event Grid](https://azure.microsoft.com/en-us/services/event-grid/).
* [What is Azure Event Grid?](https://docs.microsoft.com/en-us/azure/event-grid/overview)
* [Choose between Azure messaging services - Event Grid, Event Hubs, and Service Bus](https://docs.microsoft.com/en-us/azure/event-grid/compare-messaging-services).
* [Azure Event Grid Viewer](https://docs.microsoft.com/en-us/samples/azure-samples/azure-event-grid-viewer/azure-event-grid-viewer/).
* [Azure CLI samples for Event Grid](https://docs.microsoft.com/en-us/azure/event-grid/cli-samples).
* [The Reactive Manifesto](https://www.reactivemanifesto.org).
* [AThe Twelve-Factor App](https://12factor.net).