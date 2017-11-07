# Containers Orchestrator hands-on lab with Kubernetes
## Kubernetes Installation on Azure

> Note: A number of resources created in this demo have names that must be globally unique (e.g. ACR endpoints). In those cases the commands will include a placeholder value noted within angle brackets <> to signal that a value specific to your environment needs to be provided.

## Outline
1. Download and install Azure CLI
1. Logging in to your Azure subscription
1. Create the Kubernetes cluster
1. Install Kubectl command line
1. Download the K8s cluster configuration
1. Test your Kubernetes installation

## Details
 - You can create a cluster through CLI v2 or the Azure Portal. If you use the portal you will need to have created and provide a SSH key and Service Principal. If you use the command line you can have the SSH key and Service Principal created for you. For this tutorial, we will use the command line. 
 - For production deployments you would want to create and managed keys and Service Principals for specific purposes. To quickly create a cluster for demo/development purposes you can use the command line which will auto create:
    - SSH keys - in your home/.ssh directory
    - Service Principal - in your home/.azure directory
> Note: If you already have ssh keys in your home directory, then you should use those keys on the command line rather then allowing the CLI to create new keys which will overwrite any existing keys in your home/.ssh directory.

The following steps will create the Kubernetes cluster using command line commands: 

### Download and install Azure CLI 
If you don’t have it installed locally, follow the guide [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) to install Azure CLI v2 on your local machine.

### Login to your Azure subscription and create a new resource group

*NOTE: For simplicity's sake, we will use the same name for the Resource Group and the DNS Prefix.  To prevent DNS name collisions, make sure to suffix RESOURCE_GROUP with your username.*  e.g. `RESOURCE_GROUP=my-k8s-cluster-thfalgou`

```
RESOURCE_GROUP=my-k8s-cluster-<USER>
az group create --name $RESOURCE_GROUP --location southcentralus
```

### Create the Kubernetes cluster
```
az acs create --name $RESOURCE_GROUP --resource-group $RESOURCE_GROUP --orchestrator-type Kubernetes --dns-prefix $RESOURCE_GROUP --generate-ssh-keys
```

The above command will use ACS to create a new Kubernetes cluster named "my-k8-cluster" within the newly created resource group. The orchestrator-type parameter indicates to ACS that you are creating a kubernetes cluster with a dns parameter and to generate new ssh keys and service principals. 

### Install Kubectl command line. 
If not already installed, you can use the cli to install the k8 command line utility (kubectl).
> Note: On Windows you need to have opened the command windows with Administrator rights as the installation tries write the program to "C:\Program Files\kubectl.exe". You may also have to add “C:\Program Files” to your PATH

```
az acs kubernetes install-cli
```

### Download the k8s cluster configuration (including credentials): 
The kubectl application requires configuration data which includes the cluster endpoint and credentails. The credentails are created on the cluster admin server during installation and can be downloaded to your machine using the get-credential subcommand.
```
az acs kubernetes get-credentials --resource-group=$RESOURCE_GROUP --name=$RESOURCE_GROUP
```

### Test your Kubernetes Installation:
After downloading the cluster configuration you should be able to connect to the cluster using kubectl. For example the cluster-info command will show details about your cluster.
```
kubectl cluster-info
```

## Lab Navigation
1. [Lab Overview](./index.md)
1. [Kubernetes Installation on Azure](./step01.md) *<-- You are here*
1. [Hello-world on Kubernetes](./step02.md)
1. [Experimenting with Kubernetes Features](./step03.md)
    1. Placement
    1. Reconciliation
    1. Rolling Updates
1. [Deploying a Pod and Service from a public repository](./step04.md)
1. [Create Azure Container Service Repository (ACR)](./step05.md)
1. [Enable OMS monitoring of containers](./step06.md)
1. [Create and deploy into Kubernetes Namspaces](./step07.md)

[Back to Index](../../index.md)
