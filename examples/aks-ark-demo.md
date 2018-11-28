# ARK Demo on Azure

This demo does the following:

* Create 1 Primary AKS cluster
* Create 1 Backup AKS cluster
* Deploy ARK and Preprequisites
* Deploy Sample App
* Failover App

It uses the Azure Ark config as a basis: https://github.com/heptio/ark/blob/master/docs/azure-config.md

## Setup + Prerequisites

Assumes you have the following installed:

* Azure CLI
* kubectl
* kubectx
* kubens
* Existing Service Principal
* [Ark CLI](https://github.com/heptio/ark/releases)

Ensure the following environment variables are set with values specific to your environment:

```shell
SUBSCRIPTION_ID=
TENANT_ID=
SERVICE_PRINCIPAL=
SERVICE_PRINCIPAL_PASSWORD=
```

These environment variables also need to be set, and can be modified to fit your needs:

```shell
PRIMARY_REGION=eastus
BACKUP_REGION=westus
AKS_RG_PRI=aks-ark-pri
AKS_RG_PRI_INFRA=MC_${AKS_RG_PRI}_${AKS_RG_PRI}_${PRIMARY_REGION}
AKS_RG_BAK=aks-ark-bak
AKS_RG_BAK_INFRA=MC_${AKS_RG_BAK}_${AKS_RG_BAK}_${BACKUP_REGION}
ARK_RG=Ark_Backups
ARK_STORAGE_ACCOUNT="ark$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
```

## Create Primary AKS Cluster

```shell
az group create -n $AKS_RG_PRI -l $PRIMARY_REGION
az aks create --resource-group $AKS_RG_PRI --name $AKS_RG_PRI --location $PRIMARY_REGION --node-count 1 --service-principal=$SERVICE_PRINCIPAL --client-secret=$SERVICE_PRINCIPAL_PASSWORD
az aks get-credentials --resource-group $AKS_RG_PRI --name $AKS_RG_PRI
```

## Create Backup AKS Cluster

```shell
az group create -n $AKS_RG_BAK -l $BACKUP_REGION
az aks create --resource-group $AKS_RG_BAK --name $AKS_RG_BAK --location $BACKUP_REGION --node-count 1 --service-principal=$SERVICE_PRINCIPAL --client-secret=$SERVICE_PRINCIPAL_PASSWORD
# Don't get the credentials yet.  We're going to focus on the primary cluster
#az aks get-credentials --resource-group $AKS_RG_BAK --name $AKS_RG_BAK
```

## Setup Ark

**NOTE** These steps have been copied and updated from the [Azure config for Ark](https://github.com/heptio/ark/blob/master/docs/azure-config.md)

### Create Storage Account + Blob Container

```shell
# Create a resource group for the backups storage account and snapshots. Using the Backup Region (westus)
az group create -n $ARK_RG --location $BACKUP_REGION

# Create the storage account
az storage account create \
    --name $ARK_STORAGE_ACCOUNT \
    --resource-group $ARK_RG \
    --sku Standard_GRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot

# Create the blob container
az storage container create -n ark --public-access off --account-name $ARK_STORAGE_ACCOUNT
```

### Deploy Ark

```shell
# Deploy Ark Prerequisite
kubectl apply -f https://raw.githubusercontent.com/heptio/ark/master/examples/common/00-prereqs.yaml

# Deploy credentials
# For simplicity sake, we will re-use the credentials used to create the AKS cluster.
kubectl create secret generic cloud-credentials \
    --namespace heptio-ark \
    --from-literal AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID} \
    --from-literal AZURE_TENANT_ID=${TENANT_ID} \
    --from-literal AZURE_CLIENT_ID=${SERVICE_PRINCIPAL} \
    --from-literal AZURE_CLIENT_SECRET=${SERVICE_PRINCIPAL_PASSWORD} \
    --from-literal AZURE_RESOURCE_GROUP=${AKS_RG_PRI_INFRA}

# Deploy Ark Core
kubectl apply -f https://raw.githubusercontent.com/heptio/ark/master/examples/azure/00-ark-deployment.yaml

# Setup Ark Backup Storage Location
cat <<EOF > ark-backupstoragelocation.yaml
apiVersion: ark.heptio.com/v1
kind: BackupStorageLocation
metadata:
  name: default
  namespace: heptio-ark
spec:
  provider: azure
  objectStorage:
    bucket: ark
  config:
    resourceGroup: $ARK_RG
    storageAccount: $ARK_STORAGE_ACCOUNT
EOF
kubectl apply -f ark-backupstoragelocation.yaml

# Setup Ark Volume Snapshot Location
cat <<EOF > ark-volumesnapshotlocation.yaml
apiVersion: ark.heptio.com/v1
kind: VolumeSnapshotLocation
metadata:
  name: azure-default
  namespace: heptio-ark
spec:
  provider: azure
  config:
    apiTimeout: 2m0s
    resourceGroup: $ARK_RG
EOF
kubectl apply -f ark-volumesnapshotlocation.yaml
```

## Deploy Sample Application

We're going to deploy the example NGINX with PV from the ARK repo.  This saves `/var/log/nginx` to a PV which can be backed up

```shell
# Using cURL since wget says Github's cert has expired
curl https://raw.githubusercontent.com/heptio/ark/master/examples/nginx-app/with-pv.yaml > nginx-app-with-pv.yaml
sed -i.bak 's/<YOUR_STORAGE_CLASS_NAME>/default/' nginx-app-with-pv.yaml
kubectl apply -f nginx-app-with-pv.yaml

# The rest of the commands will be in the app namespace
kubens nginx-example

# Get the status of the Azure Disk
kubectl get deploy
# Once the deployment has 1 AVAILABLE, then you can proceed to the next step

# TODO:  We can delete this, right?
# add persistentVolumeReclaimPolicy: Retain
#kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

# Curl out to the service a few times to create logs
kubectl get svc my-nginx
# Once the EXTERNAL-IP is no longer set to <pending>, you can proceed to the next step

# View the Azure Disks
az disk list -g $AKS_RG_PRI_INFRA


SERVICE_IP=$(kubectl get svc my-nginx -o json | jq '.status.loadBalancer.ingress[0].ip' -r)
echo $SERVICE_IP

curl -s $SERVICE_IP > /dev/null
curl -s $SERVICE_IP > /dev/null
curl -s $SERVICE_IP > /dev/null

kubectl get pods

kubectl exec <nginx-pod-name> cat /var/log/nginx/access.log
# Should see 3 lines, indicating each request
```

## Manually create backup

Use the ARK CLI to manually create a backup

```shell
ark backup create nginx-backup --include-namespaces nginx-example
```

You should see the following.  **NOTE**:  This does not mean the backup was successful!

```shell
Backup request "nginx-backup" submitted successfully.
Run `ark backup describe nginx-backup` or `ark backup logs nginx-backup` for more details.
```

## Validate the backup

```shell
ark backup describe nginx-backup
```

If successful, you should see the following.  The important part is to see `Phase:  Completed`

```shell
Name:         nginx-backup
Namespace:    heptio-ark
Labels:       ark.heptio.com/storage-location=default
Annotations:  <none>

Phase:  Completed
...
Persistent Volumes:  1 of 1 snapshots completed successfully (specify --details for more information)
```

You can now check your Azure Storage Account Blob Container.  You should see files in `/ark/backups/nginx-backup`

Validate updates in Azure:

```shell
az snapshot list -g $ARK_RG
```

## Simulate Failover (locally)

```shell
kubectl delete namespaces nginx-example
```

Restore from backup

```shell
# Ensure that the PVC disk is deleted before proceeding. ~5-10 minutes
az disk list -g $AKS_RG_PRI_INFRA

ark restore create --from-backup nginx-backup
```

## Failover Application

## View Status

## Notes/Observations

* Process is relatively simple

* When performing a Recovery, Ark says that the Phase is Completed; however, that is only relevant for applying the Kubernetes resources.  For example, if creating a Service of Type=LoadBalancer, Ark will show the recovery as complete, even if the IP address has not been assigned yet.

* When recovering a Service of Type=LoadBalancer, the IP address is not guaranteed to be the same as the original.

* When restoring the pod/service, the deployment's pod name stayed the same.  Minor unexpected pleasantness.

* When deleting the namespace, it re-created the PVC.  This has caused it to re-create the PV.
  * I have tried setting the Reclaim Policy to Retain on the PV; however, this caused an error:

PVC:

```shell
Warning  ClaimMisbound  4m    persistentvolume-controller  Two claims are bound to the same volume, this one is bound incorrectly
```

POD:

```shell
Warning  FailedMount            37s (x2 over 2m)  kubelet, aks-nodepool1-36227643-0  Unable to mount volumes for pod "nginx-deployment-7d675cdc9b-9j6kz_nginx-example(5cb3354d-edda-11e8-b787-2e024b385453)": timeout expired waiting for volumes to attach/mount for pod "nginx-example"/"nginx-deployment-7d675cdc9b-9j6kz". list of unattached/unmounted volumes=[nginx-logs]
```


## Notes

Determine files are being stored

```shell
AZURE_STORAGE_KEY=$(az storage account  keys list --account-name ark66e9165c7ad9 -o json | jq '.[0].value' -r)
AZURE_STORAGE_ACCOUNT=$(az storage account list -g ark_backups -o json | jq '.[0].name' -r)
az storage blob list -c ark --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
```

## Cleanup

```shell
# Delete kubectl config
kubectl config delete-cluster $AKS_RG_PRI
kubectl config delete-context $AKS_RG_PRI
kubectl config unset users.clusterUser_${AKS_RG_PRI}_${AKS_RG_PRI}
kubectl config delete-cluster $AKS_RG_BAK
kubectl config delete-context $AKS_RG_BAK
kubectl config unset users.clusterUser_${AKS_RG_BAK}_${AKS_RG_BAK}

# Delete Azure Resources
az group delete -y -n $AKS_RG_PRI
az group delete -y -n $AKS_RG_PRI_INFRA
az group delete -y -n $AKS_RG_BAK
az group delete -y -n $AKS_RG_BAK_INFRA
az group delete -y -n $ARK_RG
```