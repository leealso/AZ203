# Develop Solutions that use Cosmos DB Storage

## Objectives
* Understand the consistency models.
* Store and query unstructured JSON data using the SQL API surface.

## What is Azure Cosmos DB?
Azure Cosmos DB is a globally distributed database engine that's designed to provide low latency, elastic scalability of throughput, well-defined semantics for data consistency, and high availability.

Azure Cosmos DB is multi-modal and takes advantage of fast, single-digit-milisecond data access using your favorite API among SQL, MongoDB, Cassandra, Tables, or Gremlin (referred to as API surfaces).

## Create and Populate a Cosmos DB Database with Data from C#
1. Create a Cosmos DB Database.
```powershell
# Set variables
$resourceGroupName = "cosmosdb-example"
$accountName= "cosmosdb-account"
$databaseName = "example-db"
$location = "westus"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l $location

# Create a SQL API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create `
 -g $resourceGroupName `
 --name $accountName `
 --kind GlobalDocumentDB `
 --locations "West US=0" "North Central US=1" `
 --default-consistency-level Strong `
 --enable-multiple-write-locations true `
 --enable-automatic-failover true

# Create a database
az cosmosdb database create `
 -g $resourceGroupName `
 --name $accountName `
 --db-name $databaseName

# List account keys
az cosmosdb list-keys `
 --name $accountName `
 -g $resourceGroupName

# List account connection strings
az cosmosdb list-connection-strings `
 --name $accountName `
 -g $resourceGroupName

az cosmosdb show `
 --name $accountName `
 -g $resourceGroupName `
 --query "documentEndpoint"

# Clean up
az group delete
 --name resourceGroupName `
 --yes
```
2. Define table entity.
```csharp
using System;
using System.IO;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using System.Net;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Collections.ObjectModel; 

namespace az203.storage.cosmosdb
{ 
    class Program
    {
        private static DocumentClient _client;
        private const string _databaseId = "myDatabase";
        private const string _collectionId = "Families";
        private const string _endpoint = "";
        private const string _key = "";

        static void Main(string[] args)
        {
            RunAsync().Wait();
        }

        private static async Task RunAsync()
        {
            _client = new DocumentClient(new Uri(_endpoint), _key);

            await _client.CreateDatabaseIfNotExistsAsync(new Database { Id = _databaseId });

            await _client.CreateDocumentCollectionIfNotExistsAsync(
                UriFactory.CreateDatabaseUri(_databaseId), 
                new DocumentCollection { 
                    Id = _collectionId,
                    PartitionKey = new PartitionKeyDefinition() { 
                        Paths = new Collection<string>(new [] { "/id" })
                    }
                });
 
            var family1 = JObject.Parse(File.ReadAllText("andersen.json"));
            var family2 = JObject.Parse(File.ReadAllText("wakefield.json"));

            await CreateDocumentIfNotExistsAsync(_databaseId, _collectionId, family1["id"].ToString(), family1);
            await CreateDocumentIfNotExistsAsync(_databaseId, _collectionId, family2["id"].ToString(), family2);

            await GetDocumentByIdAsync(_databaseId, _collectionId, "AndersenFamily");
            await GetDocumentByIdAsync(_databaseId, _collectionId, "WakefieldFamily");

            //Select the AndersenFamily document
            ExecuteSqlQuery(_databaseId, _collectionId, 
            @"
                SELECT *
                FROM Families f
                WHERE f.id = 'AndersenFamily'
            ");

            // Project the family name and city where the address city 
            // and state are the same value
            ExecuteSqlQuery(_databaseId, _collectionId, 
            @"
                SELECT {""Name"":f.id, ""City"":f.address.city} AS Family
                FROM Families f
                WHERE f.address.city = f.address.state
            ");  

            // Get all children names whose family id matches WakefieldFamily, 
            // and order by city of residence 
            ExecuteSqlQuery(_databaseId, _collectionId, 
            @"
                SELECT c.givenName
                FROM Families f
                JOIN c IN f.children
                WHERE f.id = 'WakefieldFamily'
                ORDER BY f.address.city ASC
            ");  
        }

        private static async Task CreateDocumentIfNotExistsAsync(
            string databaseId, 
            string collectionId,
            string documentId,
            JObject data)
        {
            try
            {
                await _client.ReadDocumentAsync(
                                UriFactory.CreateDocumentUri(
                                  databaseId, collectionId, documentId),
                    new RequestOptions { 
                        PartitionKey = new PartitionKey(documentId) 
                    });
                Console.WriteLine(
                    $"Family {documentId} already exists in the database");
            }
            catch (DocumentClientException de)
            {
                if (de.StatusCode == HttpStatusCode.NotFound)
                {
                    await _client.CreateDocumentAsync(
                        UriFactory.CreateDocumentCollectionUri(
                            databaseId, collectionId), 
                        data);
                    Console.WriteLine($"Created Family {documentId}");
                }
                else
                {
                    throw;
                }
            }
        }

        private static async Task<string> GetDocumentByIdAsync(
            string databaseId, 
            string collectionId,
            string documentId)
        {
            var response = await _client.ReadDocumentAsync(
                UriFactory.CreateDocumentUri(
                    databaseId, collectionId, documentId),
                new RequestOptions { 
                    PartitionKey = new PartitionKey(documentId) 
                }
            );

            Console.WriteLine(response.Resource);

            return response.Resource.ToString();
        }

        private static void ExecuteSqlQuery(
            string databaseId, string collectionId, string sql)
        {
            System.Console.WriteLine("SQL: " + sql);
            // Set some common query options
            var queryOptions = new FeedOptions { 
                MaxItemCount = -1, 
                EnableCrossPartitionQuery = true };


            var sqlQuery = _client.CreateDocumentQuery<JObject>(
                    UriFactory.CreateDocumentCollectionUri(
                        databaseId, collectionId),
                    sql, queryOptions );

            foreach (var result in sqlQuery)
            {
                Console.WriteLine(result);
            }
        }
    }
}
```

Packages required:
* [Microsoft.Azure.DocumentDB.Core](https://www.nuget.org/packages/Microsoft.Azure.DocumentDB.Core)

## References
* [Get started with Azure Cosmos DB Table API and Azure Table storage using the .NET SDK](https://docs.microsoft.com/en-us/azure/cosmos-db/tutorial-develop-table-dotnet).
