# Create Azure App Service Web Apps

## Objectives
* Create web applications using App App.
* Create App App using the Azure CLI.

## What is Azure App Service?
Azure App Service provides for hosting many Azure PaaS offerings including web applications, REST APIs, and mobile backends, Functions and Logic App. They support development using many platforms and languages.

The PaaS capabilities of an App Service also affords the ability for your application to be secure, load balanced, autoscaled, and with automated management.

Additionally, App Services have DevOps capabilities such as continuous deployment from multiple sources, package management, staging environments, custom domain, and SSL certificates.

## App Service Plans
Linux does not have F nor D tiers.

Category | Pricing Tier | Features |
------------ | -------------|------------ |
Dev/Test | F1 | Shared infrastructure, no deployment slots, no custom domains, no scaling, free |
Dev/Test | D1 | Shared infrastructure, no deployment slots, custom domains, no scaling |
Dev/Test | B1 | Dedicated infrastructure, no deployment slots, custom domains/SSL, manual scaling |
Production | S1 / P1V* | Dedicated infrastructure, deployment slots, custom domains/SSL, auto-scale |
Isolated |  | Has network isolation |

## Create an App Service Web Application using CLI and GitHub
```powershell
# Set variables
$resourceGroupName = "webapps-example"
$servicePlanName = "service-plan"
$appName = "app-example"
$repoURL = "https://github.com/Azure-Samples/php-docs-hello-world"

# Create a resource group
az group create `
 -n $resourceGroupName
 -l westus

# Create an app service plan
az appservice plan create `
 -n $servicePlanName `
 -g $resourceGroupName `
 --sku FREE

# Create a web app
az webapp create `
 -n $appName `
 -g $resourceGroupName `
 --plan $servicePlanName

# Manage deployment from git or Mercurial repositories
az webapp deployment source config `
 -n $appName `
 -g $resourceGroupName `
 --repo-url $repoURL `
 --branch master `
 --manual-integration

# Get the details of a source control deployment configuration
az webapp deployment source show `
 -n $appName `
 -g $resourceGroupName

az webapp show `
 -n $appName `
 -g $resourceGroupName

# Get the details of a web app
az webapp show `
 -n $appName `
 -g $resourceGroupName `
 --query "defaultHostName"
 -o tsv

# Synchronize from the repository. Only needed under manual integration mode
az webapp deployment source sync `
 -n $appName `
 -g $resourceGroupName

# Delete resource group
az group delete
-n $resourceGroupName `
--yes
```
2. Populate the database using the SQL API surface and the [andersen.json](andersen.json) and [wakefield.json](wakefield.json) JSON files.
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
            // Provides a client-side logical representation for the Azure Cosmos DB service
            // This client is used to configure and execute requests against the service
            _client = new DocumentClient(new Uri(_endpoint), _key);
            
            // Creates or gets a database resource in the Azure Cosmos DB service
            await _client.CreateDatabaseIfNotExistsAsync(new Database { Id = _databaseId });
            
            // Creates or gets a collection in the Azure Cosmos DB service
            await _client.CreateDocumentCollectionIfNotExistsAsync(
                // Given a database id, this creates a database link
                UriFactory.CreateDatabaseUri(_databaseId),
                // Represents a document collection in the Azure Cosmos DB service
                // A collection is a named logical container for documents
                new DocumentCollection { 
                    Id = _collectionId,
                    PartitionKey = new PartitionKeyDefinition() { 
                        Paths = new Collection<string>(new [] { "/id" })
                    }
                }
            );
 
            var family1 = JObject.Parse(File.ReadAllText("andersen.json"));
            var family2 = JObject.Parse(File.ReadAllText("wakefield.json"));

            await CreateDocumentIfNotExistsAsync(
                _databaseId, _collectionId, family1["id"].ToString(), family1);
            await CreateDocumentIfNotExistsAsync(
                _databaseId, _collectionId, family2["id"].ToString(), family2);

            await GetDocumentByIdAsync(_databaseId, _collectionId, "AndersenFamily");
            await GetDocumentByIdAsync(_databaseId, _collectionId, "WakefieldFamily");

            //Select the AndersenFamily document
            ExecuteSqlQuery(_databaseId, _collectionId, @"
                SELECT *
                FROM Families f
                WHERE f.id = 'AndersenFamily'"
            );

            // Project the family name and city where the address city 
            // and state are the same value
            ExecuteSqlQuery(_databaseId, _collectionId, @"
                SELECT {""Name"":f.id, ""City"":f.address.city} AS Family
                FROM Families f
                WHERE f.address.city = f.address.state"
            );

            // Get all children names whose family id matches WakefieldFamily, 
            // and order by city of residence 
            ExecuteSqlQuery(_databaseId, _collectionId, @"
                SELECT c.givenName
                FROM Families f
                JOIN c IN f.children
                WHERE f.id = 'WakefieldFamily'
                ORDER BY f.address.city ASC"
            );
        }

        private static async Task CreateDocumentIfNotExistsAsync(
            string databaseId, string collectionId, string documentId, JObject data)
        {
            try
            {
                // Reads a Document from the Azure Cosmos DB service
                await _client.ReadDocumentAsync(
                    // Given a database, collection and document id, this creates a document link
                    UriFactory.CreateDocumentUri(databaseId, collectionId, documentId),
                    new RequestOptions { 
                        PartitionKey = new PartitionKey(documentId) 
                    }
                );
                Console.WriteLine($"Family {documentId} already exists in the database");
            }
            catch (DocumentClientException de)
            {
                if (de.StatusCode == HttpStatusCode.NotFound)
                {
                    // Creates a Document in the Azure Cosmos DB service
                    await _client.CreateDocumentAsync(
                        // Given a database and collection id, this creates a collection link
                        UriFactory.CreateDocumentCollectionUri(databaseId, collectionId),
                        data
                    );
                    
                    Console.WriteLine($"Created Family {documentId}");
                }
                else
                {
                    throw;
                }
            }
        }

        private static async Task<string> GetDocumentByIdAsync(
            string databaseId, string collectionId, string documentId)
        {
            var response = await _client.ReadDocumentAsync(
                UriFactory.CreateDocumentUri(databaseId, collectionId, documentId),
                new RequestOptions { 
                    PartitionKey = new PartitionKey(documentId) 
                }
            );

            Console.WriteLine(response.Resource);

            return response.Resource.ToString();
        }

        private static void ExecuteSqlQuery(string databaseId, string collectionId, string sql)
        {
            // Specifies the options associated with enumeration operations in the Azure Cosmos DB service
            var queryOptions = new FeedOptions { 
                MaxItemCount = -1, 
                EnableCrossPartitionQuery = true
            };
            
            // Extension method to create a query for documents in the Azure Cosmos DB service
            var sqlQuery = _client.CreateDocumentQuery<JObject>(
                UriFactory.CreateDocumentCollectionUri(databaseId, collectionId),
                sql, queryOptions
            );

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

## Cosmos DB Consistency Levels
### CAP Theorem
You can only have two of Consitency, Availability and Partition Tolerance.
* **Consistency:** every read receives the most recente write or an error.
* **Availability:** every request receives a (non-error) response - whitout the guarantee that it contains the most recent write.
* **Partition Tolerance:** the system continues to operate despite an arbitrary number of messages being dropped (or delayed) by the network between nodes.

<p align="center">
    <img src="https://miro.medium.com/max/946/1*rxTP-_STj-QRDt1X9fdVlA.png">
</p>

### Consistency levels in Azure Cosmos DB
<p align="center">
    <img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/consistency-levels/five-consistency-levels.png">
</p>

Level | Overview | CAP | Users |


Strong Consistency | All writes are read immediately by anyone. Everyone sees the same thing. Similar to existing RDBMS  | C: Highest <br> A: Lowest <br> P: Lowest | Financial, inventory, scheduling |
Bounded Stateless | Trades off lag for ensuring reads return the most recent write. Lag can be specified in time or number of operations  | C: Consistent to a bound <br> A: Low <br> P: Low | Apps showing status, tracking. scores, tickets |
Session | Default consistency in Cosmos DB. All reads on the same session (connection) are consistent.  | C: Strong for the session <br> A: High <br> P: Moderate | Social apps, fitness apps, shopping cart |
Consistent Prefix | Bounded staleness without lag/delay. You will need to read consistent data, but it may be an older version.  | C: Low <br> A: High <br> P: Low | Social media (comments, likes), apps with updates like scores |
Eventual Consistency | Highest availabilty and performance, but no guarantee that a read within any specific time, for anyone, sees the latest data. But will eventually be consistent - no loss due to high availability.  | C: Lowest <br> A: Highest <br> P: Highest | Non-ordered updates like reviews and ratings, aggregated status |

## References
* [Consistency levels in Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/consistency-levels).
* [Getting Behind the 9-Ball: Cosmos DB Consistency Levels Explained](https://blog.jeremylikness.com/blog/2018-03-23_getting-behind-the-9ball-cosmosdb-consistency-levels/).
* [Getting started with SQL queries](https://docs.microsoft.com/en-us/azure/cosmos-db/sql-query-getting-started).
