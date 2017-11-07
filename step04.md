# Containers Orchestrator hands-on lab with Kubernetes
## Deploying a Pod and Service from a public repository

The following steps can be used to quickly deploy an image from DockerHub (a public repository) that is made available via Azure external load balancer.

The kubectl get services command will show the EXTERNAL-IP as 'Pending' until a public IP is provisioned for the service on the load balancer. Once the EXTERNAL-IP is assigned you can use that IP to render the nginx landing page.

```
kubectl run nginx --image nginx
kubectl get pods
kubectl expose deployments nginx --port=80 --type=LoadBalancer
kubectl get services
```

You can also enable access to the k8 web UI console via local proxy
```
kubectl proxy
```

The output will note the port that the proxy binds to. The console will then be available at that port on localhost. e.g. http://localhost:8001/ui

*NOTE: This will only work when running locally, and not if you're using the Azure CLI*

## Lab Navigation
1. [Lab Overview](./index.md)
1. [Kubernetes Installation on Azure](./step01.md)
1. [Hello-world on Kubernetes](./step02.md)
1. [Experimenting with Kubernetes Features](./step03.md)
    1. Placement
    1. Reconciliation
    1. Rolling Updates
1. [Deploying a Pod and Service from a public repository](./step04.md) *<-- You are here*
1. [Create Azure Container Service Repository (ACR)](./step05.md)
1. [Enable OMS monitoring of containers](./step06.md)
1. [Create and deploy into Kubernetes Namspaces](./step07.md)

[Back to Index](../../index.md)
