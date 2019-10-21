# Create Containerized Solutions
&nbsp;&nbsp;
## Objectives
* How to create a docker file to package a .NET Core application.
* How to launch an AKS cluster to run a container stored in a repository such as Docker Hub.

## What are Containers?
Containers are means of packaging, deploying, and operating software. Containers make IaaS much more agile than with virtual machines, as well as significantly more effective.

Azure provides several facilities to utilize container, including Service Fabric, Azure Kubernetes Services (AKS), and Container Instances.

## Create and Dockerize a .NET Core application
1. Create and run a .NET Core application.
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
2. Create a Dockerfile for a .NET Core application.
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
3. Build and run the Docker image.
```sh
# Build image from Dockerfile
docker build -t webapp .

# Run container using the built image
docker run -d -p 8081:80 --name mywebapp webapp
```

## What is AKS?
Azure Kubernetes Services (AKS) is a fully managed Kubernetes container orchestrator. It takes care of much of the overhead of managing your own Kubernetes infrastructure.

## Create an AKS Cluster with CLI
The following commands can be used to create a AKS cluster using the [azure-vote.yaml](azure-vote.yaml) file.
A Kubernetes manifest file defines a desired state for the cluster, such as what container images to run. The manifest used in this example is [azure-vote.yaml](azure-vote.yaml).
```powershell
# Set variables
$resourceGroupName = "aks-example"
$clusterName = "aks-cluster"

# Create a resource group
az group create `
 -n $resourceGroupName `
 -l westus

# Create AKS cluster
az aks create `
 -g $resourceGroupName `
 -n $clusterName `
 --node-count 1 `
 --generate-ssh-keys `
 --enable-addons monitoring # Enables Azure Monitor
 
 # Install Kubernetes command-line client (kubectl)
az aks install-cli

# Downloads credentials and configures the Kubernetes CLI to use them
az aks get-credentials `
 -g $resourceGroupName `
 -n $clusterName

# Get AKS cluster nodes
kubectl get nodes

# Deploy application to AKS cluster
kubectl apply `
 -f azure-vote.yaml

# Monitor deployment progress
kubectl get service azure-vote-front `
 --watch
 
# Delete AKS cluster
az group delete `
 --name resourceGroupName `
 --yes `
 --no-wait
```

## References
* [Dockerize an ASP.NET Core application](https://docs.docker.com/engine/examples/dotnetcore/)
* [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough)
