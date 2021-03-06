# Create Azure App Service Web Apps

## Objectives
* Create web applications using App Service.
* Create App Service using the Azure CLI.

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
 -n $resourceGroupName `
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

# Get the details of a web app
az webapp show `
 -n $appName `
 -g $resourceGroupName `
 --query "defaultHostName" `
 -o tsv

# Synchronize from the repository
# Only needed under manual integration mode
az webapp deployment source sync `
 -n $appName `
 -g $resourceGroupName

# Delete resource group
az group delete `
 -n $resourceGroupName `
 --yes
```

## Create an App Service Web App using Containers and Docker Hub using CLI and GitHub
```powershell
# Set variables
$resourceGroupName = "webapps-example"
$servicePlanName = "service-plan"
$appName = "app-example"
$container = "microsoft/dotnet-samples:aspnetapp"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l westus

# Create an app service plan
az appservice plan create `
 -n $servicePlanName `
 -g $resourceGroupName `
 --sku FREE `
 --is-linux

# Create a web app using a container
az webapp create `
 -n $appName `
 -g $resourceGroupName `
 --plan $servicePlanName `
 --deployment-container-image-name $container

# Configure web app settings
az webapp config appsettings set `
 -n $appName `
 -g $resourceGroupName `
 --settings WEBSITES_PORT=80

# Delete resource group
az group delete `
 -n $resourceGroupName `
 --yes
```

## References
* [App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/).
* [Create an App Service app with deployment from GitHub using Azure CLI](https://docs.microsoft.com/bs-latn-ba/azure/app-service/scripts/cli-deploy-github).
* [Web App for Containers](https://azure.microsoft.com/en-us/services/app-service/containers/).
