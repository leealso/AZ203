# Create Containerized Solutions
&nbsp;&nbsp;
## Objectives
* How to create a docker file to package a .Net Core application.
* How to launch an AKS cluster to run a container stored in a repository such as Docker Hub.

## What is a Container?
Containers are means of packaging, deploying, and operating software. Containers make IaaS much more agile than with virtual machines, as well as significantly more effective.

Azure provides several facilities to utilize container, including Service Fabric, Azure Kubernetes Services (AKS), and Container Instances.

## Create and Dockerize a .NET Core App
1. Create a .NET Core App.
```bash
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
2. Create a Dockerfile for the .NET Core App.
```dockerfile
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
3. Build container and run.
```dockerfile
docker build -t webapp .
docker run -d -p 8081:80 --name myapp webapp
```

## Azure Batch associated CLI commands
* [az batch pool create](https://docs.microsoft.com/en-us/cli/azure/batch/pool?view=azure-cli-latest#az-batch-pool-create)
* [az batch job create](https://docs.microsoft.com/en-us/cli/azure/batch/job?view=azure-cli-latest#az-batch-job-create)
* [az batch task create](https://docs.microsoft.com/en-us/cli/azure/batch/task?view=azure-cli-latest#az-batch-task-create)

### CLI commands examples
[AzureBatch.ps1](AzureBatch.ps1)

## References
* [Batch: Cloud-scale job scheduling and compute management](https://azure.microsoft.com/en-us/services/batch/)
* [Azure Batch documentation](https://docs.microsoft.com/en-us/azure/batch/)
* [Developer features](https://docs.microsoft.com/en-us/azure/batch/batch-api-basics)
* [Manage Batch resources with Azure CLI](https://docs.microsoft.com/en-us/azure/batch/batch-cli-get-started)
* [Azure CLI examples for Azure Batch](https://docs.microsoft.com/en-us/azure/batch/cli-samples)
