# Develop Solutions that use Blob Storage

## Objectives
* Create a lease on a blob with C#.

## What is Azure Blob Storage?
Azure Blob Storage is a massively scalable storage sustem for unstructured data/binary large objects.

## Working wih Blobs using C#
1. Create a Storage Account.
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
2. Populate the database using the SQL API surface and the [andersen.json](andersen.json) and [wakefield.json](wakefield.json) JSON files.
```csharp
using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;

namespace linuxacademy.az203.storage.blobs
{
    public class Blobs
    {
        public static string _connectionString = "";
        
        public static async Task RunAsync()
        {
            var storageAccount = CloudStorageAccount.Parse(_connectionString);
            var cloudBlobClient = storageAccount.CreateCloudBlobClient();

            var cloudBlobContainer = cloudBlobClient.GetContainerReference("mycontainer");
            await cloudBlobContainer.CreateAsync();

            var permissions = new BlobContainerPermissions {
                PublicAccess = BlobContainerPublicAccessType.Blob
            };
            await cloudBlobContainer.SetPermissionsAsync(permissions);

            var localFileName = "Blob.txt";
            File.WriteAllText(localFileName, "Hello, World!");

            var cloudBlockBlob = cloudBlobContainer.GetBlockBlobReference(localFileName);
            await cloudBlockBlob.UploadFromFileAsync(localFileName);

            // List the blobs in the container.
            Console.WriteLine("Listing blobs in container.");
            BlobContinuationToken blobContinuationToken = null;
            do {
                var results = await cloudBlobContainer.ListBlobsSegmentedAsync(null, blobContinuationToken);
                blobContinuationToken = results.ContinuationToken;
                foreach (var item in results.Results) {
                    Console.WriteLine(item.Uri);
                }
            } while (blobContinuationToken != null); 

            var destinationFile = localFileName.Replace(".txt", "_DOWNLOADED.txt");
            await cloudBlockBlob.DownloadToFileAsync(destinationFile, FileMode.Create);

            var leaseId = Guid.NewGuid().ToString();

            File.WriteAllText(localFileName, "New Content");

            cloudBlockBlob.AcquireLease(TimeSpan.FromSeconds(30), leaseId);

            try
            {
                await cloudBlockBlob.UploadFromFileAsync(localFileName);
            }
            catch (StorageException ex)
            {
                System.Console.WriteLine(ex.Message);
                if (ex.InnerException != null) System.Console.WriteLine(ex.InnerException.Message);
            }

            await Task.Delay(TimeSpan.FromSeconds(5));

            await cloudBlockBlob.UploadFromFileAsync(localFileName);

            // or release it
            await cloudBlockBlob.ReleaseLeaseAsync(new AccessCondition()
            {
                LeaseId = leaseId
            });

            await cloudBlobContainer.DeleteIfExistsAsync();
        }
    }
}
```

Packages required:
* [Microsoft.Azure.Storage.Blob](https://www.nuget.org/packages/Microsoft.Azure.Storage.Blob/)
* [Microsoft.Azure.Storage.Common](https://www.nuget.org/packages/Microsoft.Azure.Storage.Common/)

## References
* [Consistency levels in Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/consistency-levels).
* [Getting Behind the 9-Ball: Cosmos DB Consistency Levels Explained](https://blog.jeremylikness.com/blog/2018-03-23_getting-behind-the-9ball-cosmosdb-consistency-levels/).
* [Getting started with SQL queries](https://docs.microsoft.com/en-us/azure/cosmos-db/sql-query-getting-started).
