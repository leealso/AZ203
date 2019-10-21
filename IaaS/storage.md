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
3. Build and run the Docker image.
```sh
# Build image from Dockerfile
docker build -t webapp .

# Run container using the built image
docker run -d -p 8081:80 --name mywebapp webapp
```


## References
* [Dockerize an ASP.NET Core application](https://docs.docker.com/engine/examples/dotnetcore/).
* [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough).
