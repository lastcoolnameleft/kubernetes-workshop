# Containers Orchestrator hands-on lab with Kubernetes
## Experimenting with Kubernetes Features

We will highlight three main Kubernetes features in this section: placement, reconciliation and application rolling updates. 

## Placement
From the Kubernetes docs [here](http://kubernetes.io/docs/user-guide/configuring-containers/) and [here](http://kubernetes.io/docs/user-guide/node-selection/).


This section focuses on containers’ placement using Kubernetes, which addresses two main issues a) placing a container relative to other containers, whether required to be on the same node as a collection (i.e. pod) or on different nodes and b) which nodes to run the collection of containers relative to other collections. We will address each issue at a time.   

### Placing a Container Relative to Other Containers
Kubernetes uses the concept of Pods as a logical abstract to collect containers in the same collection, which can then be guaranteed to be deployed to the same node. 

#### Kubernetes executes containers in `Pods`. A pod containing a simple Hello World container can be specified in YAML as follows:

https://github.com/lastcoolnameleft/demos/blob/master/k8s-lab/hello-world.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec:  # specification of the pod's contents
  restartPolicy: Never
  containers:
  - name: hello
    image: "ubuntu:14.04"
    command: ["/bin/echo", "hello", "world"]
```

#### This pod can be created using the create command: 
```
kubectl create -f https://raw.githubusercontent.com/lastcoolnameleft/demos/master/k8s-lab/hello-world.yaml
```

The results should look like this
```
pod "hello-world" created
```

#### You can see the pod you created using the get command:
```
kubectl get pods --show-all
```

The results should look like this
```
NAME          READY     STATUS      RESTARTS   AGE
hello-world   0/1       Completed   0          1m
```

#### Terminated pods aren’t currently automatically deleted, so you will need to delete them manually using:
```
kubectl delete pod hello-world
```

The results should look like this
```
pod "hello-world" deleted
```

#### Let us now start a new pod with two containers. For example, the following configuration file creates two containers: a redis key-value store image, and a nginx frontend image.

https://github.com/lastcoolnameleft/demos/blob/master/k8s-lab/pod-sample.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: redis-nginx
  labels:
    app: web
spec:
  containers:
    - name: key-value-store
      image: redis
      ports:
        - containerPort: 6379
    - name: frontend
      image: nginx
      ports:
        - containerPort: 8000
```

Create the the pod:

```
kubectl create -f https://raw.githubusercontent.com/lastcoolnameleft/demos/master/k8s-lab/pod-sample.yaml
```

### Placing Pods on Various Kubernetes Nodes:
You can constrain a **pod** to only be able to run on particular **nodes** or to prefer to run on particular nodes. There are several ways to do this, and they all use **label** selectors to make the selection. Generally, such constraints are unnecessary, as the scheduler will automatically do a reasonable placement (e.g. spread your pods across nodes, not place the pod on a node with insufficient free resources, etc.) but there are some circumstances where you may want more control where a pod lands, e.g. to ensure that a pod ends up on a machine with an SSD attached to it, or to co-locate pods from two different services that communicate a lot into the same availability zone.

**nodeSelector** is the simplest form of constraint. **nodeSelector** is a field of PodSpec. It specifies a map of key-value pairs. For the pod to be eligible to run on a node, the node must have each of the indicated key-value pairs as labels (it can have additional labels as well).

#### You need to attach labels to a node using; kubectl label nodes <node-name> <label-key>=<label-value>, as follows:
Get the names of the nodes on your cluster
```
kubectl get nodes
```

then add a label to your specific node
```
kubectl label nodes kubernetes-foo-node-1.c.a disktype=ssd
```

#### You can then specify the label in your pod config file as a nodeSelector section

https://github.com/lastcoolnameleft/demos/blob/master/k8s-lab/pod-sample-2.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx2
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: ssd
```

Create the pod
```
kubectl create -f https://raw.githubusercontent.com/lastcoolnameleft/demos/master/k8s-lab/pod-sample-2.yaml
```

```
kubectl describe pod/nginx2
```

## Reconciliation
From the Kubernetes docs [here](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/).

A ReplicaSet ensures that a specified number of pod replicas are running at any given time. However, a Deployment is a higher-level concept that manages ReplicaSets and provides declarative updates to pods along with a lot of other useful features. Therefore, we recommend using Deployments instead of directly using ReplicaSets, unless you require custom update orchestration or don’t require updates at all.

This actually means that you may never need to manipulate ReplicaSet objects: use a Deployment instead, and define your application in the spec section.

[https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

A Deployment controller provides declarative updates for Pods and ReplicaSets.

You describe a desired state in a Deployment object, and the Deployment controller changes the actual state to the desired state at a controlled rate. You can define Deployments to create new ReplicaSets, or to remove existing Deployments and adopt all their resources with new Deployments. 

For example, your pods get re-created on a node after disruptive maintenance such as a kernel upgrade. A simple case is to create 1 Replication Set object in order to reliably run one instance of a Pod indefinitely.

#### Create an example of Replication Set and Deployment config. It runs 3 copies of the nginx web server.

https://github.com/lastcoolnameleft/demos/blob/master/k8s-lab/nginx-deployment.yaml

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2 # tells deployment to run 2 pods matching the template
  template: # create pods using pod definition in this template
    metadata:
      # unlike pod-nginx.yaml, the name is not included in the meta data as a unique name is
      # generated from the deployment name
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

#### Run the new pod
```
kubectl create -f https://raw.githubusercontent.com/lastcoolnameleft/demos/master/k8s-lab/nginx-deployment.yaml
```

The output should look like this
```
deployment "nginx-deployment" created
```

#### Check the status of the replica controller
```
kubectl describe deployment nginx-deployment
```

The output should look like this
```
➜  hello-world kubectl describe deployment nginx-deployment
Name:			nginx-deployment
Namespace:		default
CreationTimestamp:	Fri, 18 Aug 2017 11:30:55 -0500
Labels:			app=nginx
Annotations:		deployment.kubernetes.io/revision=1
Selector:		app=nginx
Replicas:		2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:		RollingUpdate
MinReadySeconds:	0
RollingUpdateStrategy:	25% max unavailable, 25% max surge
Pod Template:
  Labels:	app=nginx
  Containers:
   nginx:
    Image:		nginx:1.7.9
    Port:		80/TCP
    Environment:	<none>
    Mounts:		<none>
  Volumes:		<none>
Conditions:
  Type		Status	Reason
  ----		------	------
  Available 	True	MinimumReplicasAvailable
  Progressing 	True	NewReplicaSetAvailable
OldReplicaSets:	<none>
NewReplicaSet:	nginx-deployment-4234284026 (2/2 replicas created)
Events:
  FirstSeen	LastSeen	Count	From			SubObjectPath	Type		Reason			Message
  ---------	--------	-----	----			-------------	--------	------			-------
  37s		37s		1	deployment-controller			Normal		ScalingReplicaSet	Scaled up replica set nginx-deployment-4234284026 to 2
```

#### Now, you can increase the number of replicas from 3 to 5 as follows, then query your pod using “kubectl describe replicationcontrollers/nginx”:
```
kubectl scale --replicas=5 deployment/nginx-deployment
```

#### You can experiment with deleting a container and see how it come up again afterwards automatically by the replica controller, by using cmd line instructions from first part of the lab

## Rolling Updates
From the Kubernetes docs [here](http://kubernetes.io/docs/user-guide/rolling-updates/) and [here](http://kubernetes.io/docs/user-guide/update-demo/).

To update a service without an outage, `kubectl` supports what is called 'rolling update', which updates one pod at a time, rather than taking down the entire service at the same time. A rolling update applies changes to the configuration of pods being managed by a replication controller. The changes can be passed as a new replication controller configuration file; or, if only updating the image, a new container image can be specified directly.

This example demonstrates the usage of Kubernetes to perform a rolling update for a new container image on a running group of pods.

#### In the previous deployment, we used nginx:1.7.9.  Now we want to upgrade to 1.8

https://github.com/lastcoolnameleft/demos/blob/master/k8s-lab/deployment-nginx-update.yaml

```
cat deployment-nginx-update.yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.8 # Update the version of nginx from 1.7.9 to 1.8
        ports:
        - containerPort: 80
```

#### To update to container image to ngnix 1.9.1, you can use kubectl rolling-update --image to specify the new image:
```
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/demos/master/k8s-lab/deployment-nginx-update.yaml
```

The output should look like this
```
Created my-nginx-ccba8fbd8cc8160970f63f9a2696fc46
```

#### In another window, you can see that kubectl added a deployment label to the pods, whose value is a hash of the configuration, to distinguish the new pods from the old:
```
kubectl get pods -l app=nginx
```

The output should look like this
```
NAME                                              READY     STATUS    RESTARTS   AGE       DEPLOYMENT
my-nginx-ccba8fbd8cc8160970f63f9a2696fc46-k156z   1/1       Running   0          1m        ccba8fbd8cc8160970f63f9a2696fc46
my-nginx-ccba8fbd8cc8160970f63f9a2696fc46-v95yh   1/1       Running   0          35s       ccba8fbd8cc8160970f63f9a2696fc46
```

```
kubectl get rs -l app=nginx
```

The output should look like this
```
NAME                          DESIRED   CURRENT   READY     AGE
nginx-deployment-3285060500   2         2         2         4m
nginx-deployment-4234284026   0         0         0         4m
```

This is one example where the immutability of containers is a huge asset, in rolling new updates and in devops. 

For more exercises and info on Kubernetes, the Kubernetes website has a wealth of information and easy to follow on its various features ([http://kubernetes.io/docs/](http://kubernetes.io/docs/)).  

## Lab Navigation
1. [Lab Overview](./index.md)
1. [Kubernetes Installation on Azure](./step01.md)
1. [Hello-world on Kubernetes](./step02.md)
1. [Experimenting with Kubernetes Features](./step03.md) *<-- You are here*
    1. Placement
    1. Reconciliation
    1. Rolling Updates
1. [Deploying a Pod and Service from a public repository](./step04.md)
1. [Create Azure Container Service Repository (ACR)](./step05.md)
1. [Enable OMS monitoring of containers](./step06.md)
1. [Create and deploy into Kubernetes Namspaces](./step07.md)

[Back to Index](../../index.md)
