# Implement Secure Access to Services, Secrets, and Data

## Objectives
* Create and perform fundamental operations for Service Principals with Azure CLI.

## What is Service Principal?
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

## Create a Service Principal using Azure CLI
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
az role assignment delete 
    --assignee $servicePrincipal.appId 
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
az group delete 
    -n $resourceGroup 
    --yes
```

## Secure access to Blobs with a SAS token
A shared access signature (SAS) provides delegated access to resources in your storage account. With a SAS, you can grant clients access to resource in your storage account, without sharing account keys.

A SAS gives you granular control over the type of access you grant to clients who have the SAS, including:
* The interval over which the SAS is invalid.
* The permissions granted by the SAS.
* An optional IP address or range of IP addresses.
* Teh protocol over which Azure Storage will accept the SAS.

```powershell
$resourceGroup = "resourceGroup"
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
az group delete 
    -n $resourceGroup 
    --yes
```

## Securely store Web App secrets in Key Vault
## Secure access to Storage Accounts with MSI
## Implement Dynamic Data Masking and Always Encrypted
## Secure access to an AKS cluster

## References
* [What is Azure Service Bus?](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview).
* [Choose between Azure messaging services - Event Grid, Event Hubs, and Service Bus](https://docs.microsoft.com/en-us/azure/event-grid/compare-messaging-services).
* [Quickstart: Use Azure PowerShell to create a Service Bus queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-powershell).
* [Quickstart: Use the Azure CLI to create a Service Bus queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-cli).
* [Get started with Service Bus queues](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues).
* [Messages, payloads, and serialization](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messages-payloads).