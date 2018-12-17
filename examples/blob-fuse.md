# BlobFuse

Create Storage Account and Storage Container

```shell
```

## Install credentials

```shell
kubectl create secret generic blobfusecreds --from-literal accountname=ACCOUNT-NAME --from-literal accountkey="ACCOUNT-KEY" --type="azure/blobfuse"
```

## Deploy Blobfuse adapter

```shell
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.9.yaml
```

## Deploy sample application

```shell
wget -O nginx-flex-blobfuse.yaml https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/nginx-flex-blobfuse.yaml
vi nginx-flex-blobfuse.yaml

```