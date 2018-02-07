# Containers Orchestrator hands-on lab with Kubernetes

## Hello-world on Kubernetes

From the [Kubernetes Quick Start](http://kubernetes.io/docs/user-guide/quick-start/)

### To run a simple app on Kubernetes, we can use: `kubectl run`

Let us start by running a simple HTTP server: nginx. Nginix is a popular HTTP server, with a pre-built container on Docker hub. The kubectl run commands below will create two nginx replicas, listening on port 80, and a public IP address for your application.

```shell
kubectl run my-nginx --image=nginx --replicas=2 --port=80
```

Results:

```shell
deployment "my-nginx" created
```

### To expose your service to the public internet, use

```shell
kubectl expose deployment my-nginx --target-port=80 --type=LoadBalancer
```

Results:

```shell
service "my-nginx" exposed
```

### You can see that they are running by

Kubernetes will ensure that your application keeps running, by automatically restarting containers that fail, spreading containers across nodes, and recreating containers on new nodes when nodes fail.

### To find the public IP address assigned to your application

```shell
kubectl get service my-nginx
```

Results:

```shell
NAME       TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
my-nginx   LoadBalancer   10.0.13.23   <pending>     80:30872/TCP   17s
```

### To kill the application and delete its containers and public IP address

```shell
kubectl delete deployment,service my-nginx
```

Results:

```shell
deployment "my-nginx" deleted
service "my-nginx" deleted
```

## Next Steps

1. [Lab Overview](README.md)
1. [Create AKS Cluster](create-aks-cluster.md)
1. [Hello-world on Kubernetes](k8s-hello-world.md)
1. [Experimenting with Kubernetes Features](k8s-features.md)
1. [Deploying a Pod and Service from a public repository](./step04.md)
1. [Create Azure Container Service Repository (ACR)](./step05.md)
1. [Enable OMS monitoring of containers](./step06.md)
1. [Create and deploy into Kubernetes Namspaces](./step07.md)
