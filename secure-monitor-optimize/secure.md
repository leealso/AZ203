# Implement Secure Access to Services, Secrets, and Data

## Objectives
* Configuring MSI on a web app.
* Granting access to secrets in Key Vault to the MSI Service Principal.

## Service Principal and MSI
Service Principals are identities in Azure Active Directory. A Service Principal (SP) can represent an application, service, or Azure resource (such as a VM). They are similar to a user account in this sense, but purely for non-human based identity.

Principals are assigned permissions (roles), granting or revoking access to Azure resources. Often, this is performed in a least-privilege manner.

When used as an identity service such as a Web Application, or for a resource such as a VM, this is often referred to as Managed Service Identity (MSI).

A common challenge with bulding cloud applications is how to manage the credentials in your code for authenticating to cloud services. It is critical to keep these secure, and never appear in any code backing your services or configuraion resources. Key Vault can store secrets, but you still need to authenticate with Key Vault (a catch-22).

Managed Service Identities (MSI) solves this problem. MSI provides Azure services with an AAD assigned identity (a Service Principal). You can use the identity to authenticate to any service that supports Azure AD authentication with no credentials in your code.

Services supporting MSI:
* Virtual Machines
* VM Scale Sets
* App Service
* Functions
* Logic Apps
* API Management
* Container Instances

Can operate with clients that use MSI:
* Resource Manager
* Key Vault
* Data Lake
* SQL
* Event Hubs
* Service Bus
* Storage

```powershell
$servicePrincipalName = "servicePrincipal"

$servicePrincipal = (
    # Create a service principal and configure its access to Azure resources
    az ad sp create-for-rbac `
        --name $servicePrincipalName | ConvertFrom-Json
)

# Delete a service principal and its role assignments
az ad sp delete `
    --id $servicePrincipal.appId

# Get the details of a service principal
az ad sp show `
    --id $servicePrincipal.appId
    
# List service principals by name
az ad sp list `
    --display-name $servicePrincipalName

# List role assignments
az role assignment list `
    --assignee $servicePrincipal.appId

# List role definitions
az role definition list `
    --output json `
    --query '[].{"roleName":roleName, "description":description}'

# List role definitions
az role definition list `
    --custom-role-only false `
    --output json `
    --query '[].{"roleName":roleName, "description":description, "roleType":roleType}'

# List role definitions
az role definition list `
    --name "Contributor"

# List role definitions
az role definition list `
    --name "Contributor" `
    --output json `
    --query '[].{"actions":permissions[0].actions, "notActions":permissions[0].notActions}'

$resourceGroup = "resourceGroup"
$servicePlan = "webAppServicePlan"
$appName = "webApp"
$location = "westus"

# Create a resource group
az group create `
    -n $resourceGroup ` 
    -l $location

# Create an app service plan
az appservice plan create `
    -n $servicePlan `
    -g $resourceGroup `
    --sku FREE

# Create a web app using a container
az webapp create `
    -g $resourceGroup `
    --plan $servicePlan `
    -n $appName 

# Get the details of a web app
$webApp = (
    # Get the details of a web app
    az webapp show `
        --name $appName `
        -g $resourceGroup  | ConvertFrom-Json
)

# Create a new role assignment for a user, group, or service principal
az role assignment create `
    --role "Website Contributor" `
    --assignee $servicePrincipal.appId `
    --scope $webApp.id

# Delete role assignments
az role assignment delete `
    --assignee $servicePrincipal.appId `
    --role "Contributor"

$systemAssignedId = (
    # Assign or disable managed service identity to the web app
    az webapp identity assign `
        -g $resourceGroup `
        -n $appName
)

# Display web app's managed service identity
az webapp identity show `
    -n $appName `
    -g $resourceGroup

# Delete a web app
az webapp delete `
    -n $appName `
    -g $resourceGroup

# Delete a service principal and its role assignments
az ad sp delete `
    --id $servicePrincipal.appId

# Delete resource group
az group delete `
    -n $resourceGroup `
    --yes
```

## Secure access to Blobs with a SAS token
A shared access signature (SAS) provides delegated access to resources in your storage account. With a SAS, you can grant clients access to resource in your storage account, without sharing account keys.

A SAS gives you granular control over the type of access you grant to clients who have the SAS, including:
* The interval over which the SAS is invalid.
* The permissions granted by the SAS.
* An optional IP address or range of IP addresses.
* The protocol over which Azure Storage will accept the SAS.

```powershell
$resourceGroup = "resourceGroup"
$storageAccount = "storageAccount"
$container = "container"
$location = "westus"

# Create a resource group
az group create `
    -n $resourceGroup ` 
    -l $location
    
# Create storage account
az storage account create `
    -g $resourceGroup `
    -n $storageAccount `
    -l $location `
    --sku Standard_LRS

$storageAccountKey = $(
    # List the primary and secondary keys for a storage account
    az storage account keys list `
        --account-name $storageAccount `
        -g $resourceGroup `
        --query "[0].value" `
        --output tsv
)

# Create a container in a storage account
az storage container create `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --name $container

# Upload a file to a storage blob
az storage blob upload `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --file image.jpg `
    --container-name $container `
    --name image.jpg

# Create the url to access a blob
az storage blob url `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --container-name $container `
    --name image.jpg

$now = [DateTime]::UtcNow
$start = $now.ToString('yyyy-MM-ddTHH:mmZ')
$end = $now.AddMinutes(5).ToString('yyyy-MM-ddTHH:mmZ')

$sasToken = (
    # Generates a shared access signature for the blob
    az storage blob generate-sas `
        --account-name $storageAccount `
        --account-key $storageAccountKey `
        --container-name $container `
        --name image.jpg `
        --permissions r `
        --start $start `
        --expiry $end
)

# Create the url to access a blob with the SAS token
az storage blob url `
    --account-name $storageAccount `
    --account-key $storageAccountKey `
    --container-name $container `
    --name image.jpg `
    --sas $sasToken `
    -o tsv

# Delete resource group
az group delete `
    -n $resourceGroup `
    --yes
```

## Securely store Web App secrets in Key Vault
Key Vault is a service for securelt storeing secrets. It will lock up those secrets in a vault that is either software or hardware encrypted. It will then only allow access to those secrets by those granted permissions.

But this is a problem. Your application would need to keep the credentials for authenticating with Key Vault within its configuration, hence makng the whole security thing insecure. This has been solved with MSI.

```powershell
$resourceGroup = "resourceGroup"
$keyVault = "keyVault"
$servicePrincipalName = "servicePrincipal"
$location = "westus"

# Create a resource group
az group create `
    -n $resourceGroup ` 
    -l $location

# Create a key vault
az keyvault create `
    -n $keyVault `
    -g $resourceGroup `
    --sku standard 

# Create a secret (if one doesn't exist) or update a secret in a key vault
az keyvault secret set `
    --vault-name $keyVault `
    --name "connectionString" `
    --value "this is the connection string"

# Get a specified secret from a given key vault
az keyvault secret show `
    --vault-name $keyVault `
    --name connectionString

$servicePrincipal = (
    # Create a service principal and configure its access to Azure resources
    az ad sp create-for-rbac `
        --name $servicePrincipalName | ConvertFrom-Json
)

$tenantId = (
    # Get the details of a subscription
    az account show `
        --query tenantId `
        -o tsv
)

# Log in to Azure using service principal
az login `
    --service-principal `
    --username $servicePrincipal.appId `
    --password $servicePrincipal.password `
    --tenant $tenantId

# Get a specified secret from a given key vault
az keyvault secret show `
    --vault-name $keyVault `
    --name connectionString

# Log in to Azure using user account
az login

# Update security policy settings for a key vault
az keyvault set-policy `
    --name $keyVault `
    --spn $servicePrincipal.Name `
    --secret-permissions get

# Log in to Azure using service principal
az login `
    --service-principal `
    --username $servicePrincipal.appId `
    --password $servicePrincipal.password `
    --tenant $tenantId

# Get a specified secret from a given key vault
az keyvault secret show `
    --vault-name $keyVault `
    --name connectionString

# Delete a service principal and its role assignments
az ad sp delete `
    --id $servicePrincipal.appId

# Delete a key vault
az keyvault delete `
    --name $keyVault

# Delete resource group
az group delete `
    -n $resourceGroup `
    --yes
```

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.KeyVault;

namespace az203.secure
{
    class Program
    {
        static void Main(string[] args)
        {
            RunAsync().Wait();
        }

        private static async Task RunAsync()
        {
            // Instantiate a new KeyVaultClient object, with an access token to Key Vault
            var azureServiceTokenProvider = new AzureServiceTokenProvider();
            var keyVaultClient = new KeyVaultClient(
                new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback)
            );

            var keyVaultUrl = "https://mykeyvault.vault.azure.net/";
            // Asynchronously gets a secret
            var secret = await keyVaultClient.GetSecretAsync(keyVaultUrl, "connectionString");
            System.Console.WriteLine(secret.Value);
        }
    }
}
```

## Secure access to Storage Accounts with MSI
Storage accounts can also be secured with MSI, hence allowing your C# to not require local configuration with any credentials such as storage account keys or SAS tokens.

```powershell
$resourceGroup = "resourceGroup"
$servicePrincipalName = "servicePrincipal"
$storageAccount = "storageAccount"
$container = "container"
$location = "westus"

# Create a resource group
az group create `
    -n $resourceGroup ` 
    -l $location
    
# Create Storage Account
az storage account create `
    -g $resourceGroup `
    -n $storageAccount `
    -l $location `
    --sku Standard_LRS

$servicePrincipal = (
    # Create a service principal and configure its access to Azure resources
    az ad sp create-for-rbac `
        --name $servicePrincipalName | ConvertFrom-Json
)

# List role assignments
az role assignment list `
    --assignee $servicePrincipal.appId

# Delete role assignments
az role assignment delete `
    --assignee $servicePrincipal.appId `
    --role "Contributor"

# List role assignments
az role assignment list `
    --assignee $servicePrincipal.appId

$tenantId = (
    # Get the details of a subscription
    az account show `
        --query tenantId `
        -o tsv
)

# Log in to Azure using service principal
az login `
    --service-principal `
    --username $servicePrincipal.appId `
    --password $servicePrincipal.password `
    --tenant $tenantId

# Create a new role assignment for a user, group, or service principal
az role assignment create `
    --role "Reader" `
    --assignee $servicePrincipal.appId `

# Log in to Azure using service principal
az login `
    --service-principal `
    --username $servicePrincipal.appId `
    --password $servicePrincipal.password `
    --tenant $tenantId

# List containers in a storage account
az storage container list `
 --account-name $storageAccount

$storageAccountId = (
    # Show storage account properties
    az storage account show `
        -n $storageAccount `
        --query id `
        -o tsv
)

$servicePrincipalId = (
    # Get the details of a service principal
    az ad sp show `
        --id $servicePrincipal.appId `
        --query objectId `
        -o tsv
)

# Log in to Azure using user account
az login
 
# Create a new role assignment for a user, group, or service principal
az role assignment create `
    --role "Storage Account Contributor" `
    --assignee-object-id $servicePrincipalId `
    --scope $storageAccountId

# Log in to Azure using service principal
az login `
    --service-principal `
    --username $servicePrincipal.appId `
    --password $servicePrincipal.password `
    --tenant $tenantId

# Create a container in a storage account
az storage container create `
    --account-name $storageAccount `
    --name $container

# List containers in a storage account
az storage container list `
 --account-name $storageAccount

# Log in to Azure using user account
az login

# Delete a service principal and its role assignments
az ad sp delete `
    --id $servicePrincipal.appId

# Delete resource group
az group delete `
    -n $resourceGroup `
    --yes
```

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Shared;
using Microsoft.WindowsAzure.Storage.Auth;

namespace az203.secure
{
    class Program
    {
        static void Main(string[] args)
        {
            runAsync().Wait();
        }

        private static async Task runAsync()
        {
            // Request an access token to a storage account
            var azureServiceTokenProvider = new AzureServiceTokenProvider();
            var tokenCredential = new TokenCredential(
                await azureServiceTokenProvider.GetAccessTokenAsync("https://storage.azure.com/")
            );
            // Represents a set of credentials used to authenticate access to a Microsoft Azure storage account
            var storageCredentials = new StorageCredentials(tokenCredential);

            try
            {
                // Represents a Microsoft Azure Storage account
                var cloudStorageAccount = new CloudStorageAccount(
                    storageCredentials, 
                    useHttps: true, 
                    accountName: "storageAccount", 
                    endpointSuffix: "core.windows.net"
                );
                // Creates the Blob service client.
                var cloudBlobClient = cloudStorageAccount.CreateCloudBlobClient();

                // Returns a reference to a CloudBlobContainer object with the specified name
                var containerReference = cloudBlobClient.GetContainerReference("container");
                containerReference.CreateIfNotExists();
            }
            catch (Exception ex)
            {
                System.Console.WriteLine(ex.Message);
            }
        }
    }
}
```
## Implement Dynamic Data Masking and Always Encrypted
## Secure access to an AKS cluster

## References
* [What is Azure Service Bus?](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview).
* [Choose between Azure messaging services - Event Grid, Event Hubs, and Service Bus](https://docs.microsoft.com/en-us/azure/event-grid/compare-messaging-services).
* [Quickstart: Use Azure PowerShell to create a Service Bus queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-powershell).
* [Quickstart: Use the Azure CLI to create a Service Bus queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-cli).
* [Get started with Service Bus queues](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues).
* [Messages, payloads, and serialization](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messages-payloads).