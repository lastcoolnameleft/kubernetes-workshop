# Containers Orchestrator hands-on lab with Kubernetes
## Hello-world on Kubernetes

From the [Kubernetes Quick Start](http://kubernetes.io/docs/user-guide/quick-start/)

### To run a simple app on Kubernetes, we can use: `kubectl run` 
Let us start by running a simple HTTP server: nginx. Nginix is a popular HTTP server, with a pre-built container on Docker hub. The kubectl run commands below will create two nginx replicas, listening on port 80, and a public IP address for your application.
```
kubectl run my-nginx --image=nginx --replicas=2 --port=80
```

The output should look like this
```
deployment "my-nginx" created
```
 
### To expose your service to the public internet, use:
```
kubectl expose deployment my-nginx --target-port=80 --type=LoadBalancer
```

The output should look like this
```
service "my-nginx" exposed
```
 
### You can see that they are running by:  


Kubernetes will ensure that your application keeps running, by automatically restarting containers that fail, spreading containers across nodes, and recreating containers on new nodes when nodes fail.

### To find the public IP address assigned to your application
```
kubectl get service my-nginx
```

The output should look like this
```
NAME         CLUSTER_IP       EXTERNAL_IP       PORT(S)                AGE
my-nginx     10.179.240.1     25.1.2.3          80/TCP                 8s
```
 
### To kill the application and delete its containers and public IP address, do: 
```
kubectl delete deployment,service my-nginx
```

The output should look like this
```
deployment "my-nginx" deleted
service "my-nginx" deleted
```


## Lab Navigation
1. [Lab Overview](./index.md)
1. [Kubernetes Installation on Azure](./step01.md)
1. [Hello-world on Kubernetes](./step02.md) *<-- You are here*
1. [Experimenting with Kubernetes Features](./step03.md)
    1. Placement
    1. Reconciliation
    1. Rolling Updates
1. [Deploying a Pod and Service from a public repository](./step04.md)
1. [Create Azure Container Service Repository (ACR)](./step05.md)
1. [Enable OMS monitoring of containers](./step06.md)
1. [Create and deploy into Kubernetes Namspaces](./step07.md)

[Back to Index](../../index.md)
