# Develop Solutions that use Storage Tables
&nbsp;&nbsp;
## Objectives
* How to perform query functions to Azure Table Storage.

## What is Azure Table Storage?
Azure Table Storage is a highly scalable, semi-structured (you do not have to predefine the table structure), NoSQL key-value store. Access is via REST and OData, with SDK's available for multiple languages and platforms.

The data model/access is entity-based with entities keyed by a partition and row key. Entities are automatically partitioned based on the partition key. Entities can also be queried based upon attributes values (as well as key values).

## Code CRUD and Query Operations with C#
1. Create a Storage Account
```powershell
# Set variables
$resourceGroupName = "table-example"
$storageAccountName = "storage-account"
$location = "westus"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l $location

# Create Storage Account
az storage account create `
 -g $resourceGroupName `
 -n $storageAccountName `
 -l $location `
 --sku Standard_LRS

# Get Storage Account connection string
az storage account show-connection-string
 -n $storageAccountName `
 --query "conectionString"

# Delete resource group
az group delete `
 --name resourceGroupName `
 --yes `
 --no-wait
```
2. Define table entity.
```csharp
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.Storage.Table;

namespace az203.storage.tables
{
    public class User : TableEntity
    {
        public string Country { get { return this.PartitionKey; }}
        public string Email { get { return this.RowKey; }}
        public string Name { get; set; }
        public string LastName { get; set; }

        public User() {}
        public User(string email, string country,
        string name, string lastName = null)
        {
            this.PartitionKey = region;
            this.RowKey = email;
            this.Name = name;
            this.LastName = lastName;
        }

        public override string ToString()
        {
            return $"Country(pk):{Country} Email(rk):{Email} Name:{Name} LastName:{LastName}";
        }
    }
}
```
3. Query the table storage from C#.
```csharp
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Table;

namespace az203.storage.tables
{
    public class UserRepository
    {
        private static string _connectionString = "";

        public static async Task Example()
        {
            // Parses a connection string and returns a cloud storage account created from the connection string
            var storageAccount = CloudStorageAccount
            .Parse(_connectionString);
            // Creates a new Table service client
            var tableClient = storageAccount.CreateCloudTableClient();
            
            // Get table reference
            var usersTable = tableClient.GetTableReference("Users");
            // Gets a CloudTable object with the specified name
            await usersTable.CreateIfNotExistsAsync();

            await DeleteAllUsersAsync(usersTable);
            
            var user1 = new User("john@example.com", "Canada", "John");
            await AddAsync(usersTable, user1);
            
            var users = new List<User> {
                new User("allan@example.com", "US", "Allan", "Smith"),
                new User("ken@example.com", "Spain", "Kenneth", "Jhones")
            };
            await AddBatchAsync(usersTable, users);

            var user2 = await GetAsync<User>(
            usersTable, "Canada", "john@example.com");
            System.Console.WriteLine(user2);

            users = await FindUsersByNameAsync(usersTable, "Allan");
            users.ForEach(Console.WriteLine);
        }

        public static async Task AddAsync<T>(
        CloudTable table, T entity) where T : TableEntity
        {
            // Returns a TableOperation instance to insert the specified entity into Microsoft Azure storage
            var insertOperation = TableOperation.Insert(entity);
            await table.ExecuteAsync(insertOperation);
        }

        public static async Task AddBatchAsync<T>(
        CloudTable table, IEnumerable<T> entities) where T : TableEntity
        {
            var batchOperation = new TableBatchOperation();
            foreach (var entity in entities)
                batchOperation.Insert(entity);
            await table.ExecuteBatchAsync(batchOperation);
        }

        public static async Task<T> GetAsync<T>(
        CloudTable table, string pk, string rk) where T : TableEntity
        {
            var retrieve = TableOperation.Retrieve<User>(pk, rk);
            var result = await table.ExecuteAsync(retrieve);
            return (T)result.Result;
        }

        public static async Task DeleteAsync<T>(
        CloudTable table, T entity) where T : TableEntity
        {
            var retrieve = TableOperation.Delete(entity);
            await table.ExecuteAsync(retrieve);
        }

        public static async Task<List<User>> FindUsersByNameAsync(
        CloudTable table, string name)
        {
            var filterCondition = TableQuery.GenerateFilterCondition("Name", QueryComparisons.Equal, name);
            var query = new TableQuery<User>().Where(filterCondition);
            var results = await table.ExecuteQuerySegmentedAsync(query, null);
            return results.ToList();
        }

        public static async Task DeleteAllUsersAsync(CloudTable table)
        {
            var users = new [] {
                await GetAsync<User>(table, "US", "allan@example.com"),
                await GetAsync<User>(table, "Spain", "ken@example.com"),
                await GetAsync<User>(table, "Canada", "john@example.com")
            }.ToList();
            users.ForEach(async user =>
            {
                if (user != null)
                    await DeleteAsync(table, user);
            });
        }
    }
}
```


## References
* [Dockerize an ASP.NET Core application](https://docs.docker.com/engine/examples/dotnetcore/).
* [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough).
