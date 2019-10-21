# Implement Batch Jobs by Using Azure Batch Services
&nbsp;&nbsp;
## Objectives
* Create an azure batch account and run a batch job/task using the Azure CLI.
* Know the sequence of CLI commands to createa and tun a batch job/task.

## What is Azure Batch?
Azure Batch is an IaaS offering that provides a service for submtting large quantities of similar tasks into Azure to be deployed to virtual machines for execution.

Batch works well with intrinsically parallel (also known as "embarrassingly parallel") workloads. Intrinsically parallel workloads are those where the applications can run independently, and each instance completes part of the work.

There is no additional charge for using Batch. You only pay for the underlying resources consumed, such as the virtual machines, storage, and networking.

![Azure Batch workflow](https://docs.microsoft.com/en-us/azure/batch/media/batch-technical-overview/tech_overview_03.png)

## Components of an Azure Batch solution
* **Azure Batch Account:** top level construct, responsible for authenticating request, scheduling task to virtual machines, and moving data in and out of the batch processing from the storage account that’s associated with the batch account.
  * **Job:** container for one or more tasks that are similar in processing and should be scheduled onto virtual machines. The job configures those virtual machines, moves data in and out of them as well as your executable code.
    * **Task:** describes which code to execute along with where to get the input and where to put the output data (defaults to files in the storage account).
  * **Pool:** similarly configured virtual machines that will be used to support execution of one or more jobs.
* **Azure Storage Account:** used to store resource files and output files.

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
