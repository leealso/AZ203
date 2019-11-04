# Develop Event-Based Solutions

## Objectives
* Understand topics and subscriptions that form the publish and subscribe model.
* Understand several of the means of configuring routing of events.
* Understand JSON configuration content and structure.

## What is Event Grid?
Azure Event Grid is a fully managed event routing service that provides for event consumption using a publish-subscribe model.

Event Grid focuses on a reactive model of messaging where messages represent "events" instead of "commands" which are more of a focus of messaging systems (such as Service Bus).

It can be used to wire code to react to both Azure and non-Azure events, and for near real-time event scenarios. It's a great way of building a backbone for serverless and event-driven applications (reactive programming/applications, and cloud-native 12-factor applications).

<p align="center">
    <img src="https://docs.microsoft.com/en-us/azure/event-grid/media/overview/functional-model.png"/>
</p>

## Deliver Messages at Scale with Event Grid
1. Create a Search Service ang get access keys.
```powershell
# Set variables
$resourceGroupName = "search-example"
$serviceName = "search-service"
$location = "westus"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l $location

# Creates a search service in the given resource group
az search service create `
 --name $serviceName `
 -g $resourceGroupName `
 --sku free

# Gets the primary and secondary admin API keys for the specified Azure Search service
az search admin-key show `
 --service-name $serviceName `
 -g $resourceGroupName `
 --query "primaryKey"
 
# Returns the list of query API keys for the given Azure Search service
az search query-key list `
 --service-name $serviceName `
 -g $resourceGroupName `
 --query "[0].key"

# Delete resource group
az group delete `
 -n $resourceGroupName `
 --yes
```

## References
* [Event Grid](https://azure.microsoft.com/en-us/services/event-grid/).
* [What is Azure Event Grid?](https://docs.microsoft.com/en-us/azure/event-grid/overview)
* [Choose between Azure messaging services - Event Grid, Event Hubs, and Service Bus](https://docs.microsoft.com/en-us/azure/event-grid/compare-messaging-services).
* [Azure Event Grid Viewer](https://docs.microsoft.com/en-us/samples/azure-samples/azure-event-grid-viewer/azure-event-grid-viewer/).
* [Azure CLI samples for Event Grid](https://docs.microsoft.com/en-us/azure/event-grid/cli-samples).
* [The Reactive Manifesto](https://www.reactivemanifesto.org).
* [Azure CLI samples for Event Grid](https://docs.microsoft.com/en-us/azure/event-grid/cli-samples).