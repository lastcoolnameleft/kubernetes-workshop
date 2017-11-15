# Containers Orchestrator hands-on lab with Kubernetes

## Persist storage on Azure

This tutorial will cover different ways to persist data inside a Kubernetes cluster in Azure.

Typically in Kubernetes, you use a Persistent Volume Claim (PVC) to request a data disk and then create a Persistent Volume from the PVC to mount a the container.

### Using an managed disk with Persistent Volume Claim

In this exercise, we will:
* Create the Storage Class
* Create the Persistent Volume Claim for that Storage Class
* Create the Deployment with 1 Pod using 2 containers that share the PVC
* Cordon the node the pods are running
* Kill the Pod and watch the node and PVC migrate to the new node


#### Create the Storage Class

The Storage Class is how Kubernetes knows how to request storage from the underlying infrastructure.  In this case, we are creating a storage class for our cluster to use Azure Managed Disks using LRS redundancy.

Additional details:
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#new-azure-disk-storage-class-starting-from-v172

```
kubectl apply -f https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/storage/azure-disk-managed-pvc/storage-class.yaml?raw=1

kubectl get storageclass
```

####  Create the Persistent Volume Claim for that Storage Class

Persistent Volumes is how we persist data (via Volumes) that we want to exist beyond the lifespand of a Pod.  A Persistent Volume Claim is how we request Persistent Volumes from the underlying infrastructure.

Additional details:
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims

```
kubectl apply -f https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/storage/azure-disk-managed-pvc/pvc.yaml?raw=1

kubectl get pvc
```


#### Create the Deployment with 1 Pod using 2 containers that share the PVC

See https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes for more details

We will now create a Deployment because we want to showcase creating a new Pod that writes to the volume, delete that Pod, watch the ReplicaSet re-create the pod on a new node and then watch the Volume mounted inside the new Pod.

The Deployment has a Pod with 2 containers (backend-writer and frontend-webserver) and Service that exposes a public endpoint.

The backend writer container writes a new line to a file in the Persistent Volume every second with the date/time + the Pod's hostname.  The frontend webserver container reads that file and serves it via Apache.

```
kubectl apply -f https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/storage/azure-disk-managed-pvc/deployment.yaml?raw=1

kubectl get pod,deploy,service
```


It may take ~3 minutes for the Azure Load Balancer + Public IP to resolve

```
IP=`kubectl get svc/azure-managed-hdd -o json  | jq '.status.loadBalancer.ingress[0].ip' -r`
curl $IP 
```

Once the service is verified to be up, reverse the contents of the file and only show the last 20 lines.  

*Run this command in a separate window to watch the volume migrate to a different host.*
```
watch "curl $IP | tail -r | head -20"
```


#### Cordon the node the pods are running


Now that we have verified the service is up and appending to the logs, let's kill the pod and have a new one start on a new node 


First, disable scheduling on the existing node.  This prevents any new pods being started on this host.  Then kill the pod to have it restart on a different node.
```
NODE=`kubectl get pods -l app=azure-managed-hdd -o json | jq '.items[0].spec.nodeName' -r`
kubectl cordon $NODE

POD_NAME=`kubectl get pods -l app=azure-managed-hdd -o json | jq '.items[0].metadata.name' -r`
kubectl delete $POD_NAME
```

Now we should see the pod start up on a new node.  Go back to your curl window to watch the service become unavailable and then available again with the writes to a new node.
```
kubectl get pod
```



## Acknowledgments

This page is inspired by these two articles here:

https://blogs.technet.microsoft.com/livedevopsinjapan/2017/05/16/azure-disk-tips-for-kubernetes/

https://github.com/kubernetes/examples/tree/master/staging/volumes/azure_disk/claim/managed-disk/managed-hdd