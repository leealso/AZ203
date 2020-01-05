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

## Sending and receiving messages with C#
```csharp
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Azure.ServiceBus;

namespace az203.thirparty.servicebus
{
    class Program 
    {
        static void Main(string[] args) 
        {
            RunAsync().Wait();
        }

        static async Task RunAsync()
        {
            const string serviceBusConnectionString = 
                "Endpoint=sb://az203sb.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=t9gYOnESyhuWkuKaqovzpVMOoPgWPxb8fgj7wydOKIx=";
            const string queueName = "queue";
            const int delay = 2000;
            const int numMessageToSend = 10;

            // QueueClient can be used for all basic interactions with a Service Bus Queue
            var queueClient = new QueueClient
            (
                serviceBusConnectionString, 
                queueName
            );

            // Registers a message handler and begins a new thread to receive messages
            queueClient.RegisterMessageHandler(
                async (message, cancellationToken) => 
                {
                    Console.WriteLine(
                        $"Received message: SequenceNumber:{message.SystemProperties.SequenceNumber} Body:{Encoding.UTF8.GetString(message.Body)}"
                    );

                    if (delay > 0)
                        await Task.Delay(delay);
                    
                    // Completes a Message using its lock token. 
                    // This will delete the message from the queue
                    await queueClient.CompleteAsync(message.SystemProperties.LockToken);
                },
                // Provides options associated with message pump processing
                new MessageHandlerOptions
                (
                    exception => 
                    {
                        Console.WriteLine($"Message handler encountered an exception {exception.Exception}.");
                        var context = exception.ExceptionReceivedContext;
                        Console.WriteLine($"- Endpoint: {context.Endpoint}");
                        Console.WriteLine($"- Entity Path: {context.EntityPath}");
                        Console.WriteLine($"- Executing Action: {context.Action}");
                        return Task.CompletedTask;
                    }
                )
                {
                    // Maximum number of concurrent calls to the callback the message pump should initiate
                    MaxConcurrentCalls = 5,
                    // Indicates whether the message pump should call CompleteAsync 
                    // on messages after the callback has completed processing
                    AutoComplete = false
                }
            );

            for (var i = 0; i < numMessageToSend; i++) 
            {
                var messageBody = $"Message {i}";
                var message = new Message(Encoding.UTF8.GetBytes(messageBody));

                Console.WriteLine($"Sending message: {messageBody}");

                // Sends a message to Service Bus
                await queueClient.SendAsync(message);
            }

            Task.Delay(30000).Wait();

            // Closes the Client and the connections opened by it
            await queueClient.CloseAsync();
        }
    }
}
```

## Correlation and routing in Service Bus
Several of the Message class's properties can be used to implement message correlation and routing: To, ReplyTo, ReplyToSessionId, MessageId, CorrelationId, and SessionId. These can be used to implement several patterns:
* Simple Request/Reply.
* Multicast Request/Reply.
* Multiplexing.
* Multiplexed Request/Reply.

### Examples of request/reply patterns
* You can set the reply message's CorrelationId to the request message's MessageId and send reply to a single reply queue. This way you can match a response to a request but you can't match a response to a client.
* To match a response to a client you can use a reply queue per client and set the request message's ReplyTo to the client's reply queue.
* For better scalability you can use a single reply queue and set the response message's ReplyToSessionId to the request message's SessionId and send reply to a single queue or queue in the request message's ReplyTo.

## References
* [What is Azure Service Bus?](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview).
* [Choose between Azure messaging services - Event Grid, Event Hubs, and Service Bus](https://docs.microsoft.com/en-us/azure/event-grid/compare-messaging-services).
* [Quickstart: Use Azure PowerShell to create a Service Bus queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-powershell).
* [Quickstart: Use the Azure CLI to create a Service Bus queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-cli).
* [Get started with Service Bus queues](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues).
* [Messages, payloads, and serialization](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messages-payloads).