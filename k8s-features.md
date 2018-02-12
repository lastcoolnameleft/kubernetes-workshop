# Containers Orchestrator hands-on lab with Kubernetes

## Experimenting with Kubernetes Features

We will highlight three main Kubernetes features in this section: placement, reconciliation and application rolling updates.

## Placement

From the Kubernetes docs [here](http://kubernetes.io/docs/user-guide/configuring-containers/) and [here](http://kubernetes.io/docs/user-guide/node-selection/).

This section focuses on containers’ placement using Kubernetes, which addresses two main issues a) placing a container relative to other containers, whether required to be on the same node as a collection (i.e. pod) or on different nodes and b) which nodes to run the collection of containers relative to other collections. We will address each issue at a time.

### Placing a Container Relative to Other Containers

Kubernetes uses the concept of Pods as a logical abstract to collect containers in the same collection, which can then be guaranteed to be deployed to the same node.

#### Kubernetes executes containers in `Pods`. A pod containing a simple Hello World container can be specified in YAML as follows

For this next section, we will use this K8S Manifest file:
<https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/hello-world.yaml>

#### This pod can be created using the create command

```shell
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/hello-world.yaml
```

Results:

```shell
pod "hello-world" created
```

#### You can see the pod you created using the get command

```shell
kubectl get pods --show-all
```

#### Let us now start a new pod with two containers. For example, the following configuration file creates two containers: a redis key-value store image, and a nginx frontend image

For this next section, we will use this K8S Manifest file:
<https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/pod-sample.yaml>

Create the the pod:

```shell
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/pod-sample.yaml
```

### Placing Pods on Various Kubernetes Nodes

You can constrain a **pod** to only be able to run on particular **nodes** or to prefer to run on particular nodes. There are several ways to do this, and they all use **label** selectors to make the selection. Generally, such constraints are unnecessary, as the scheduler will automatically do a reasonable placement (e.g. spread your pods across nodes, not place the pod on a node with insufficient free resources, etc.) but there are some circumstances where you may want more control where a pod lands, e.g. to ensure that a pod ends up on a machine with an SSD attached to it, or to co-locate pods from two different services that communicate a lot into the same availability zone.

**nodeSelector** is the simplest form of constraint. **nodeSelector** is a field of PodSpec. It specifies a map of key-value pairs. For the pod to be eligible to run on a node, the node must have each of the indicated key-value pairs as labels (it can have additional labels as well).

#### Attach labels to a node

You can attach a label to a node via: `kubectl label nodes <node-name> <label-key>=<label-value>`

Get the names of the nodes on your cluster

```shell
kubectl get nodes
```

then add a label to your specific node

```shell
NODE_NAME=$(kubectl get nodes -o name | head -1)
kubectl label $NODE_NAME disktype=ssd
```

#### You can then specify the label in your pod config file as a nodeSelector section

<https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/pod-sample-2.yaml>

Create the pod

```shell
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/pod-sample-2.yaml
```

```shell
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

### Create an example of Replication Set and Deployment config. It runs 3 copies of the nginx web server

<https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/nginx-deployment.yaml>

#### Run the new pod

```shell
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/nginx-deployment.yaml
```

Results:

```shell
deployment "nginx-deployment" created
```

#### Check the status of the replica controller

```shell
kubectl describe deployment nginx-deployment
```

#### Now, you can increase the number of replicas from 3 to 5 as follows, then query your pod using “kubectl describe replicationcontrollers/nginx”

```shell
kubectl scale --replicas=5 deployment/nginx-deployment
```

#### You can experiment with deleting a container and see how it come up again afterwards automatically by the replica controller, by using cmd line instructions from first part of the lab

## Rolling Updates

From the Kubernetes docs [here](http://kubernetes.io/docs/user-guide/rolling-updates/) and [here](http://kubernetes.io/docs/user-guide/update-demo/).

To update a service without an outage, `kubectl` supports what is called 'rolling update', which updates one pod at a time, rather than taking down the entire service at the same time. A rolling update applies changes to the configuration of pods being managed by a replication controller. The changes can be passed as a new replication controller configuration file; or, if only updating the image, a new container image can be specified directly.

This example demonstrates the usage of Kubernetes to perform a rolling update for a new container image on a running group of pods.

### In the previous deployment, we used nginx:1.7.9.  Now we want to upgrade to 1.8

<https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/deployment-nginx-update.yaml>

#### To update to container image to ngnix 1.9.1, you can use kubectl rolling-update --image to specify the new image

```shell
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/deployment-nginx-update.yaml
```

Results:

```shell
deployment "nginx-deployment" configured
```

#### View the pods and Replica sets

You can see that kubectl added a deployment label to the pods, whose value is a hash of the configuration, to distinguish the new pods from the old

```shell
kubectl get pods -l app=nginx
kubectl get rs -l app=nginx
```

This is one example where the immutability of containers is a huge asset, in rolling new updates and in devops.

For more exercises and info on Kubernetes, the Kubernetes website has a wealth of information and easy to follow on its various features ([http://kubernetes.io/docs/](http://kubernetes.io/docs/)).

## Cleanup

```shell
kubectl delete -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/hello-world.yaml
kubectl delete -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/pod-sample.yaml
kubectl delete -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/pod-sample-2.yaml
kubectl delete -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/nginx-deployment.yaml
kubectl label $NODE_NAME disktype-
```
