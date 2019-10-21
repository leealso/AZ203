# Create Containerized Solutions
&nbsp;&nbsp;
## Objectives
* How to create a docker file to package a .Net Core application.
* How to launch an AKS cluster to run a container stored in a repository such as Docker Hub.

## What is a Container?
Containers are means of packaging, deploying, and operating software. Containers make IaaS much more agile than with virtual machines, as well as significantly more effective.

Azure provides several facilities to utilize container, including Service Fabric, Azure Kubernetes Services (AKS), and Container Instances.

## Create and Dockerize a .NET Core App
1. Create and run a .NET Core App.
```sh
# Create directory
mkdir webapp

# Move to directory
cd webapp

# Create new MVC web app
dotnet new mvc

# Build web app
dotnet build

# Run web app
dotnet run
```
2. Create a Dockerfile for a .NET Core App.
```dockerfile
# Use dotnet SDK as base image
FROM microsoft/dotnet:sdk AS build-env
WORKDIR /app

# Copy csproj and restore
COPY webapp/*.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY ./webapp ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM microsoft/dotnet:aspnetcore-runtime
WORKDIR /app
COPY --from=build-env /app/out .
ENTRYPOINT ["dotnet", "webapp.dll"]
```
3. Build and run container.
```sh
# Build image from Dockerfile
docker build -t webapp .

# Run container using the built image
docker run -d -p 8081:80 --name mywebapp webapp
```

## What is AKS?
Azure Kubernetes Services (AKS) is a fully managed Kubernetes container orchestrator. It takes care of much of the overhead of managing your own Kubernetes infrastructure.

## Create an AKS Cluster with CLI
The following commands can be used to create a AKS cluster based on the [azure-vote.yaml](azure-vote.yaml) file.
```powershell
$resourceGroupName = "aks-example"
$clusterName = "aks-cluster"

az group create -n $resourceGroupName `
 -l westus

az aks create -g $resourceGroupName `
 -n $clusterName `
 --node-count 1 `
 --generate-ssh-keys `
 --enable-addons monitoring

az aks get-credentials `
 -g $resourceGroupName `
 -n $clusterName

kubectl get nodes

kubectl apply -f azure-vote.yaml

kubectl get service azure-vote-front `
 --watch
```

## References
* [Batch: Cloud-scale job scheduling and compute management](https://azure.microsoft.com/en-us/services/batch/)
* [Azure Batch documentation](https://docs.microsoft.com/en-us/azure/batch/)
* [Developer features](https://docs.microsoft.com/en-us/azure/batch/batch-api-basics)
* [Manage Batch resources with Azure CLI](https://docs.microsoft.com/en-us/azure/batch/batch-cli-get-started)
* [Azure CLI examples for Azure Batch](https://docs.microsoft.com/en-us/azure/batch/cli-samples)
