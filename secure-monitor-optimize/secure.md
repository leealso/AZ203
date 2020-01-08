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

$appName = "webApp"
$resourceGroup = "resourceGroup"
$servicePlan = "webAppServicePlan"
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

$sysid = (
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