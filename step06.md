# Containers Orchestrator hands-on lab with Kubernetes
## Enable OMS monitoring of containers

This expands on the steps described [here](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-oms) by using a k8 secret to store the workspace id and key.

 - Go to the OMS portal and get the workspace id and a key (see the page referenced in the prior link).
 - Create a k8 secret to hold the workspace id and key. The following command creates a generic secret named oms-agent-secret that holds the properties WSID and KEY. Substitute your WorkspaceID and WorkspaceKey for the placholder values.

```
kubectl create secret generic oms-agent-secret --from-literal=WSID=<WorkspaceID> --from-literal=KEY=<WorkspaceKey>
```

Note two points in the file k8-demo-enable-oms.yml
 - The deployment type is DaemonSet which means one instance will be deployed to each agent Node
 - The reference to the secret created in the prior step to hold the OMS WorkspaceID and WorkspaceKey

Deploy the agent with the following command:
```
kubectl create -f k8-demo-enable-oms.yml
```

Within a few minutes you should see metrics and logs for containers deployed in the k8 cluster.

## Lab Navigation
1. [Lab Overview](./index.md)
1. [Kubernetes Installation on Azure](./step01.md)
1. [Hello-world on Kubernetes](./step02.md)
1. [Experimenting with Kubernetes Features](./step03.md)
    1. Placement
    1. Reconciliation
    1. Rolling Updates
1. [Deploying a Pod and Service from a public repository](./step04.md)
1. [Create Azure Container Service Repository (ACR)](./step05.md)
1. [Enable OMS monitoring of containers](./step06.md) *<-- You are here*
1. [Create and deploy into Kubernetes Namspaces](./step07.md)

[Back to Index](../../index.md)
