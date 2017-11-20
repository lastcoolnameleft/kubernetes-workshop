# Containers Orchestrator hands-on lab with Kubernetes

## Persist storage on Azure with Azure Files

[Azure Files](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-introduction) are a way to manage file shares that are accessible via the industry standard Server Message Block (SMB) protocol.  In this walkthrough, we will use Azure Files to persist data inside Pods.

Typically in Kubernetes, you use a Persistent Volume Claim (PVC) to request a data disk and then create a Persistent Volume (PV) from the PVC to mount a the container.

One key difference between managing via Azure Files and Azure Managed Disks is that with Azure Files, you can mount to multiple VM's simultaneously.  This comes at a sacrifice of I/O throughput.

### Using an managed disk with Persistent Volume Claim

In this exercise, we will:
* Create the Storage Class
* Create the Persistent Volume Claim for that Storage Class
* Create the Deployment with 1 Pod using 2 containers that share the PVC
* [Cordon](https://kubernetes.io/docs/user-guide/kubectl/v1.7/#cordon) the node the pods are running
  * This is to prevent scheduling new Pods on the existing Node
* Scale the Deployment to 2 replicas 
* Validate writes are happening to the same file on different VM

#### Create the Storage Class

The Storage Class is how Kubernetes knows how to request storage from the underlying infrastructure.  In this case, we are creating a storage class for our cluster to use Azure Files in our Storage Account.

Additional details:
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#azure-file


```
REGION=<YOUR K8S CLUSTER REGION>
STORAGE_ACCOUNT=<STORAGE ACCOUNT NAME TO CREATE>
RESOURCE_GROUP=<RESOURCE GROUP VM's ARE IN.  USUALLY DIFFERENT THAN RG ACS SERVICE IS IN>

# If you do not have a Storage Account already, create one in the same Resource Group as your VM's
az storage account create -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP -l $REGION --kind Storage --sku Standard_LRS
CONN_STRING=$(az storage account show-connection-string -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP --query 'connectionString' -o tsv)
az storage share create --name ${STORAGE_ACCOUNT}shr --quota 2048 --connection-string $CONN_STRING
# End of creating new Storage Account


wget  https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/storage/azure-file-pvc/storage-class.yaml 

sed -ie "s/location: eastus/location: $REGION/" storage-class.yaml
sed -ie "s/storageAccount: tmfaksstorage/storageAccount: $STORAGE_ACCOUNT/" storage-class.yaml

cat storage-class.yaml

kubectl apply -f storage-class.yaml
kubectl get storageclass
```

####  Create the Persistent Volume Claim for that Storage Class

Persistent Volumes is how we persist data (via Volumes) that we want to exist beyond the lifespand of a Pod.  A Persistent Volume Claim is how we request Persistent Volumes from the underlying infrastructure.

Additional details:
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims

```
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/storage/azure-file-pvc/pvc.yaml

kubectl get pvc
```


#### Create the Deployment with 1 Pod using 2 containers that share the PVC

See https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes for more details

We will now create a Deployment because we want to showcase creating a new Pod that writes to the volume, delete that Pod, watch the ReplicaSet re-create the pod on a new node and then watch the Volume mounted inside the new Pod.

The Deployment has a Pod with 2 containers (backend-writer and frontend-webserver) and Service that exposes a public endpoint.

The backend writer container writes a new line to a file in the Persistent Volume every second with the date/time + the Pod's hostname.  The frontend webserver container reads that file and serves it via Apache.

```
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/storage/azure-file-pvc/deployment.yaml 

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


#### Run a replica on a different node

Now that we have verified the service is up and appending to the logs, let's create a new instance and on a new node.

Azure Files allows us to attach a shared volume to multiple nodes at a time.

First, disable scheduling on the existing node.  This prevents any new pods being started on this host.
```
NODE=`kubectl get pods -l app=azure-volume-file -o json | jq '.items[0].spec.nodeName' -r`
kubectl cordon $NODE
```

Now set the number of replicas for the deployment to 2:
```
kubectl scale deploy/azure-volume-file --replicas=2
```

Now we should see a new pod start up on a different node.

```
kubectl get pod
```

Go back to your curl window to watch the service write two logs every second, once from each host.

## Summary

In this step, we've created a Azure File based Storage Class, Persistent Volume Claim, and a Deployment with a Pod with 2 containers using the Persistent Volume.  We verified that one container in the Pod could write to the volume and another container in the Pod could read from it.  We then cordon'ed the node to prevent scheduling on it and set the replicas to 2 which started the pod on a different node and verified that the service was still available and both pods were writing to the same file at the same time.



## Acknowledgments

This walkthrough was inspired by these articles:

https://blogs.technet.microsoft.com/livedevopsinjapan/2017/05/16/azure-disk-tips-for-kubernetes/

https://github.com/kubernetes/examples/tree/master/staging/volumes/azure_disk/claim/managed-disk/managed-hdd
