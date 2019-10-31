# Develop Solutions that use Blob Storage

## Objectives
* Create a lease on a blob with C#.
* Controlling access to blobs in a concurrency pattern.

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
2. Work wih Blobs using C#.
```csharp
using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;

namespace az203.storage.blobs
{
    public class Blobs
    {
        public static string _connectionString = "";
        
        public static async Task RunAsync()
        {
            // Parses a connection string and returns a cloud storage account created from
            // the connection string
            var storageAccount = CloudStorageAccount.Parse(_connectionString);
            // Creates the Blob service client
            var cloudBlobClient = storageAccount.CreateCloudBlobClient();

            // Returns a reference to a CloudBlobContainer object with the specified name
            var cloudBlobContainer = cloudBlobClient.GetContainerReference("mycontainer");
            // Creates a container
            await cloudBlobContainer.CreateAsync();

            // Represents the permissions for a container
            var permissions = new BlobContainerPermissions {
                PublicAccess = BlobContainerPublicAccessType.Blob
            };
            // Sets permissions for the container
            await cloudBlobContainer.SetPermissionsAsync(permissions);

            var localFileName = "Blob.txt";
            File.WriteAllText(localFileName, "Hello, World!");

            // Gets a reference to a block blob in this container
            var cloudBlockBlob = cloudBlobContainer.GetBlockBlobReference(localFileName);
            // Upload a file to a blobs. If the blob already exists, it will be overwritten
            await cloudBlockBlob.UploadFromFileAsync(localFileName);

            Console.WriteLine("Listing blobs in container.");
            BlobContinuationToken blobContinuationToken = null;
            do {
                // Returns a result segment containing a collection of blob items in the container
                var results = await cloudBlobContainer.ListBlobsSegmentedAsync(null, blobContinuationToken);
                blobContinuationToken = results.ContinuationToken;
                foreach (var item in results.Results) {
                    Console.WriteLine(item.Uri);
                }
            } while (blobContinuationToken != null); 

            var destinationFile = localFileName.Replace(".txt", "_DOWNLOADED.txt");
            // Download the contents of a blob to a file
            await cloudBlockBlob.DownloadToFileAsync(destinationFile, FileMode.Create);

            var leaseId = Guid.NewGuid().ToString();

            File.WriteAllText(localFileName, "New Content");
            
            // Acquires a lease on this blob
            cloudBlockBlob.AcquireLease(TimeSpan.FromSeconds(30), leaseId);

            try
            {
                // Upload a file to a blob.
                // If the blob already exists, it will be overwritten
                await cloudBlockBlob.UploadFromFileAsync(localFileName);
            }
            catch (StorageException ex)
            {
                System.Console.WriteLine(ex.Message);
                if (ex.InnerException != null)
                    System.Console.WriteLine(ex.InnerException.Message);
            }

            await Task.Delay(TimeSpan.FromSeconds(5));

            await cloudBlockBlob.UploadFromFileAsync(localFileName);

            // Release the lease on this blob
            await cloudBlockBlob.ReleaseLeaseAsync(new AccessCondition()
            {
                LeaseId = leaseId
            });
            
            // Delete the blob if it already exists
            await cloudBlobContainer.DeleteIfExistsAsync();
        }
    }
}
```

Packages required:
* [Microsoft.Azure.Storage.Blob](https://www.nuget.org/packages/Microsoft.Azure.Storage.Blob/)
* [Microsoft.Azure.Storage.Common](https://www.nuget.org/packages/Microsoft.Azure.Storage.Common/)

## References
* [Quickstart: Azure Blob storage client library for .NET](https://docs.microsoft.com/th-th/azure////storage/blobs/storage-quickstart-blobs-dotnet?tabs=linux).
* [Managing Concurrency in Microsoft Azure Storage](https://azure.microsoft.com/en-us/blog/managing-concurrency-in-microsoft-azure-storage-2/).
