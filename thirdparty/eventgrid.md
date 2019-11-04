# Develop Event-Based Solutions

## Objectives
* Understand topics and subscriptions that form the publish and subscribe model.
* Understand several of the means of configuring routing of events.
* Understand JSON configuration content and structure.


## What is Event Grid?
Azure Event Grid is a fully managed event routing service that provides for event consumption using a publish-subscribe model.

Event Grid focuses on a reactive model of messaging where messages represent "events" instead of "commands" which are more of a focus of messaging systems (such as Service Bus).

It can be used to wire code to react to both Azure and non-Azure events, and for near real-time event scenarios. It's a great way of building a backbone for serverless and event-driven applications (reactive programming/applications, and cloud-native 12-factor applications).

<p style="text-align:center">
    <img src="https://docs.microsoft.com/en-us/azure/event-grid/media/overview/functional-model.png"/>
</p>

## Create and Populate a Search Index with Data using C# and CLI
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
2. Create and populate a search index based on the [Hotel](Hotel.cs) model.
```csharp
using System;
using System.Linq;
using System.Threading;
using Microsoft.Azure.Search;
using Microsoft.Azure.Search.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Spatial;

namespace az203.thirdparty.search
{
    class Program
    {
        static void Main(string[] args)
        {
            var configuration = new ConfigurationBuilder().AddJsonFile("appsettings.json").Build();

            var searchServiceName = configuration["SearchServiceName"];
            var adminApiKey = configuration["SearchServiceAdminApiKey"];
            var queryApiKey = configuration["SearchServiceQueryApiKey"];

            // Client that can be used to manage and query indexes and documents, 
            // as well as manage other resources, on an Azure Search service
            var serviceClient = new SearchServiceClient(
               searchServiceName, 
               // Credentials used to authenticate to an Azure Search service
               new SearchCredentials(adminApiKey)
            );

            // Represents an index definition in Azure Search, which describes the 
            // fields and search behavior of an index
            var definition = new Index()
            {
                Name = "hotels",
                Fields = FieldBuilder.BuildForType<Hotel>()
            };

            // Creates a new Azure Search index
            serviceClient.Indexes.Create(definition);

            // Creates a new index client for querying and managing documents in a given index
            var indexClientForUpload = serviceClient.Indexes.GetClient("hotels");

            var hotels = new Hotel[]
            {
                new Hotel()
                { 
                    HotelId = "1", 
                    BaseRate = 199.0, 
                    Description = "Best hotel in town",
                    DescriptionFr = "Meilleur hôtel en ville",
                    HotelName = "Fancy Stay",
                    Category = "Luxury", 
                    Tags = new[] { "pool", "view", "wifi", "concierge" },
                    ParkingIncluded = false, 
                    SmokingAllowed = false,
                    LastRenovationDate = new DateTimeOffset(2010, 6, 27, 0, 0, 0, TimeSpan.Zero), 
                    Rating = 5, 
                    Location = GeographyPoint.Create(47.678581, -122.131577)
                },
                new Hotel()
                { 
                    HotelId = "2", 
                    BaseRate = 79.99,
                    Description = "Cheapest hotel in town",
                    DescriptionFr = "Hôtel le moins cher en ville",
                    HotelName = "Roach Motel",
                    Category = "Budget",
                    Tags = new[] { "motel", "budget" },
                    ParkingIncluded = true,
                    SmokingAllowed = true,
                    LastRenovationDate = new DateTimeOffset(1982, 4, 28, 0, 0, 0, TimeSpan.Zero),
                    Rating = 1,
                    Location = GeographyPoint.Create(49.678581, -122.131577)
                },
                new Hotel() 
                { 
                    HotelId = "3", 
                    BaseRate = 129.99,
                    Description = "Close to town hall and the river"
                }
            };

            // Creates a new IndexBatch for uploading documents to the index
            var batch = IndexBatch.Upload(hotels);
            // Sends a batch of upload, merge, and/or delete actions to the Azure Search index
            indexClientForUpload.Documents.Index(batch);

            // Client that can be used to query an Azure Search index and upload, 
            // merge, or delete documents
            var indexClientForQuery = new SearchIndexClient(
               searchServiceName, 
               "hotels", 
               new SearchCredentials(queryApiKey)
            );

            // Parameters for filtering, sorting, faceting, paging, and other search query behaviors
            var parameters = new SearchParameters()
            {
                Select = new[] { "hotelName" }
            };

            // Searches for documents in the Azure Search index
            var results = indexClientForQuery.Documents.Search<Hotel>("budget", parameters);
            WriteDocuments(results);

            parameters = new SearchParameters()
            {
                Filter = "baseRate lt 150",
                Select = new[] { "hotelId", "description" }
            };

            results = indexClientForQuery.Documents.Search<Hotel>("*", parameters);
            WriteDocuments(results);

            parameters = new SearchParameters()
            {
                OrderBy = new[] { "lastRenovationDate desc" },
                Select = new[] { "hotelName", "lastRenovationDate" },
                Top = 2
            };

            results = indexClientForQuery.Documents.Search<Hotel>("*", parameters);
            WriteDocuments(results);

            parameters = new SearchParameters();
            results = indexClientForQuery.Documents.Search<Hotel>("motel", parameters);
            WriteDocuments(results);
        }

        private static void WriteDocuments(DocumentSearchResult<Hotel> searchResults)
        {
            foreach (SearchResult<Hotel> result in searchResults.Results)
            {
                Console.WriteLine(result.Document);
            }

            Console.WriteLine();
        }
    }
}
```
Packages required:
* [Microsoft.Azure.Search](https://www.nuget.org/packages/Microsoft.Azure.Search)

## References
* [How to use Azure Search from a .NET Application](https://docs.microsoft.com/en-us/azure/search/search-howto-dotnet-sdk).
* [How full text search works in Azure Search](https://docs.microsoft.com/en-us/azure/search/search-lucene-query-architecture).
* [How to rebuild an Azure Search index](https://docs.microsoft.com/en-us/azure/search/search-howto-reindex).